"""API tests using an in-memory fake Firestore (no real Firebase needed).

The fake mimics the google-cloud-firestore client API that the repositories
use: collection().document().set/get/update/delete, where(), order_by(), and
subcollections. SERVER_TIMESTAMP and ArrayUnion/ArrayRemove are resolved.
"""
import datetime
from unittest.mock import patch

from django.contrib.auth import get_user_model
from google.cloud.firestore import SERVER_TIMESTAMP
from google.cloud.firestore import ArrayRemove, ArrayUnion
from rest_framework.test import APITestCase


# ---------------------------------------------------------------------------
# Fake Firestore
# ---------------------------------------------------------------------------
def _resolve(value, current=None):
    if value is SERVER_TIMESTAMP:
        return datetime.datetime.now(datetime.timezone.utc)
    if isinstance(value, ArrayUnion):
        base = current if isinstance(current, list) else []
        return base + [v for v in value._values if v not in base]
    if isinstance(value, ArrayRemove):
        base = current if isinstance(current, list) else []
        return [v for v in base if v not in value._values]
    return value


class FakeCollection:
    def __init__(self, db, path):
        self._db = db
        self.path = path
        self._docs = db._stores.setdefault(path, {})
        self._filters = []
        self._order = None

    def document(self, doc_id=None):
        if doc_id is None:
            doc_id = f"auto_{len(self._docs) + 1}_{id(self)}"
        return FakeDoc(self, doc_id)

    def where(self, field, op, value):
        q = FakeCollection(self._db, self.path)
        q._filters = self._filters + [(field, op, value)]
        q._order = self._order
        return q

    def order_by(self, field, direction="ASCENDING"):
        q = FakeCollection(self._db, self.path)
        q._filters = list(self._filters)
        q._order = (field, direction)
        return q

    def get(self):
        results = [FakeDoc(self, i) for i, d in self._docs.items() if d is not None]
        for field, op, value in self._filters:
            results = [r for r in results if self._match(r, field, op, value)]
        if self._order:
            field, direction = self._order
            results.sort(
                key=lambda r: (r.to_dict() or {}).get(field),
                reverse=(direction == "DESCENDING"),
            )
        return results

    @staticmethod
    def _match(doc, field, op, value):
        actual = (doc.to_dict() or {}).get(field)
        if op == "==":
            return actual == value
        if op == "!=":
            return actual != value
        if op == "array_contains":
            return isinstance(actual, list) and value in actual
        return True


class FakeDoc:
    def __init__(self, collection, doc_id):
        self._collection = collection
        self.id = doc_id

    @property
    def exists(self):
        return self._collection._docs.get(self.id) is not None

    def to_dict(self):
        return self._collection._docs.get(self.id)

    def set(self, data):
        self._collection._docs[self.id] = {k: _resolve(v) for k, v in data.items()}

    def update(self, data):
        doc = dict(self._collection._docs.get(self.id, {}))
        for k, v in data.items():
            doc[k] = _resolve(v, doc.get(k))
        self._collection._docs[self.id] = doc

    def delete(self):
        self._collection._docs.pop(self.id, None)

    def get(self):
        return self

    def collection(self, name):
        return self._collection._db.collection(f"{self._collection.path}/{self.id}/{name}")


class FakeFirestore:
    def __init__(self):
        self._stores = {}

    def collection(self, path):
        return FakeCollection(self, path)


# ---------------------------------------------------------------------------
# Base test case wiring Firebase functions to the fake
# ---------------------------------------------------------------------------
class FirebaseTestCase(APITestCase):
    def setUp(self):
        self.db = FakeFirestore()
        self._token_uid = {"test-id-token": "testuid"}
        self._patchers = [
            patch("api.services.firebase_service.get_firestore", return_value=self.db),
            patch("api.services.firebase_service.verify_id_token", side_effect=self._verify),
            patch("api.services.firebase_service.create_firebase_user", side_effect=self._create_user),
            patch("api.services.firebase_service.sign_in_with_password", side_effect=self._sign_in),
        ]
        for p in self._patchers:
            p.start()
        self.addCleanup(self._stop_patchers)

    def _stop_patchers(self):
        for p in self._patchers:
            p.stop()

    def _verify(self, token):
        uid = self._token_uid.get(token, "testuid")
        return {"uid": uid, "email": "arafat@campusgo.app", "name": "Arafat Hossain"}

    def _create_user(self, email, password, name=""):
        return "testuid"

    def _sign_in(self, email, password):
        return {
            "idToken": "test-id-token",
            "refreshToken": "test-refresh-token",
            "localId": "testuid",
            "email": email,
        }

    def register_payload(self, **overrides):
        payload = {
            "name": "Arafat Hossain",
            "email": "arafat@campusgo.app",
            "password": "password123",
            "userType": "student",
            "studentId": "12345678901",
            "university": "BUBT",
        }
        payload.update(overrides)
        return payload


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
class AuthTests(FirebaseTestCase):
    def test_student_register(self):
        response = self.client.post("/api/auth/register/", self.register_payload(), format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["userType"], "student")
        self.assertEqual(response.data["studentId"], "12345678901")
        self.assertTrue(self.db._stores["users"]["testuid"])

    def test_student_register_rejects_wrong_id_length(self):
        response = self.client.post(
            "/api/auth/register/", self.register_payload(studentId="123"), format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_login_returns_tokens_and_user(self):
        self.db._stores.setdefault("users", {})["testuid"] = {
            "name": "Arafat Hossain",
            "email": "arafat@campusgo.app",
            "userType": "student",
        }
        response = self.client.post(
            "/api/auth/login/",
            {"email": "arafat@campusgo.app", "password": "password123"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["access"], "test-id-token")
        self.assertEqual(response.data["user"]["userType"], "student")


# ---------------------------------------------------------------------------
# Authenticated resource tests
# ---------------------------------------------------------------------------
class AuthedTestCase(FirebaseTestCase):
    def setUp(self):
        super().setUp()
        self.db._stores.setdefault("users", {})["testuid"] = {
            "name": "Arafat Hossain",
            "email": "arafat@campusgo.app",
            "userType": "student",
        }
        self.client.credentials(HTTP_AUTHORIZATION="Bearer test-id-token")


class AuthProfileTests(AuthedTestCase):
    def test_me_returns_department_and_persists_firebase_uid(self):
        response = self.client.get("/api/auth/user/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["department"], "")

        User = get_user_model()
        user = User.objects.get(username="fb_testuid")
        self.assertEqual(user.firebase_uid, "testuid")

    def test_public_profile_endpoint(self):
        self.db._stores["users"]["otheruid"] = {
            "name": "Other Student",
            "email": "other@campusgo.app",
            "userType": "student",
        }
        response = self.client.get("/api/users/otheruid/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Other Student")


class PostTests(AuthedTestCase):
    def test_create_and_like_post(self):
        create = self.client.post(
            "/api/posts/", {"caption": "Hello campus!", "type": "general"}, format="json"
        )
        self.assertEqual(create.status_code, 201)
        post_id = create.data["id"]

        like = self.client.post(f"/api/posts/{post_id}/like/", {"currentlyLiked": False}, format="json")
        self.assertEqual(like.status_code, 200)
        self.assertIn("testuid", like.data["likedBy"])

        save = self.client.post(f"/api/posts/{post_id}/save/", {"currentlySaved": False}, format="json")
        self.assertEqual(save.status_code, 200)

        saved_feed = self.client.get("/api/posts/saved/")
        self.assertEqual(saved_feed.status_code, 200)
        self.assertEqual(len(saved_feed.data), 1)


class TutorTests(AuthedTestCase):
    def test_apply_for_tuition(self):
        self.db._stores.setdefault("tutors", {})["tutor1"] = {
            "title": "Tutor Needed For Math",
            "subject": "Mathematics",
            "userId": "otheruid",
            "posterName": "Other Student",
            "applicants": [],
        }
        apply = self.client.post(
            "/api/tutors/tutor1/apply/",
            {"phone": "01711112222", "note": "Interested"},
            format="json",
        )
        self.assertEqual(apply.status_code, 201)
        self.assertEqual(apply.data["status"], "pending")

        again = self.client.post("/api/tutors/tutor1/apply/", {"phone": "01711112222"}, format="json")
        self.assertEqual(again.status_code, 400)


class ConversationTests(AuthedTestCase):
    def test_direct_message(self):
        self.db._stores.setdefault("users", {})["otheruid"] = {
            "name": "Other Student",
            "email": "other@campusgo.app",
            "userType": "student",
        }
        send = self.client.post(
            "/api/conversations/send/",
            {"otherUserId": "otheruid", "message": "Hi there!"},
            format="json",
        )
        self.assertEqual(send.status_code, 201)
        self.assertEqual(send.data["message"], "Hi there!")

        inbox = self.client.get("/api/conversations/")
        self.assertEqual(inbox.status_code, 200)
        self.assertEqual(len(inbox.data), 1)

        conv_id = inbox.data[0]["id"]
        messages = self.client.get(f"/api/conversations/{conv_id}/messages/")
        self.assertEqual(messages.status_code, 200)
        self.assertEqual(len(messages.data), 1)


class StudyGroupTests(AuthedTestCase):
    def test_create_join_and_message(self):
        create = self.client.post(
            "/api/study-groups/",
            {"name": "CSE-300 Squad", "subject": "SDP", "maxMembers": 5},
            format="json",
        )
        self.assertEqual(create.status_code, 201)
        group_id = create.data["id"]
        self.assertEqual(create.data["members"], ["testuid"])

        self.db._stores.setdefault("users", {})["otheruid"] = {
            "name": "Other Student",
            "email": "other@campusgo.app",
            "userType": "student",
        }
        self._token_uid["other-token"] = "otheruid"
        self.client.credentials(HTTP_AUTHORIZATION="Bearer other-token")

        join = self.client.post(f"/api/study-groups/{group_id}/join/")
        self.assertEqual(join.status_code, 200)
        self.assertIn("otheruid", join.data["members"])

        msg = self.client.post(
            f"/api/study-groups/{group_id}/messages/", {"message": "Hello team"}, format="json"
        )
        self.assertEqual(msg.status_code, 201)


class BookAndHostelTests(AuthedTestCase):
    def test_create_book_keeps_price_numeric(self):
        create = self.client.post(
            "/api/books/",
            {"title": "DSA", "author": "Karumanchi", "price": 350.5, "condition": "Good"},
            format="json",
        )
        self.assertEqual(create.status_code, 201)
        self.assertIsInstance(create.data["price"], float)
        self.assertEqual(create.data["price"], 350.5)

    def test_create_hostel_keeps_rent_numeric(self):
        create = self.client.post(
            "/api/hostels/",
            {"name": "Green Hostel", "type": "Boys", "location": "BUBT", "rent": 4500, "gender": "Boys"},
            format="json",
        )
        self.assertEqual(create.status_code, 201)
        self.assertIsInstance(create.data["rent"], float)
        self.assertEqual(create.data["rent"], 4500.0)
