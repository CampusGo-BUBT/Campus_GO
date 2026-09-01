"""Authentication business logic (Firebase Auth + Firestore `users` docs)."""
import logging

from rest_framework.exceptions import NotFound

from api.repositories.user_repository import UserRepository
from api.services import firebase_service

logger = logging.getLogger(__name__)

_repo = UserRepository()


class AuthService:
    def register(self, name, email, password, user_type, student_id="", university="", phone=""):
        """Create a Firebase Auth account + Firestore `users/{uid}` profile."""
        uid = firebase_service.create_firebase_user(email, password, name)
        return _repo.create(
            uid,
            {
                "name": name,
                "email": email,
                "userType": user_type,
                "studentId": student_id or "",
                "university": university or "",
                "phone": phone or "",
            },
        )

    def login(self, email, password):
        """Sign in via Firebase Identity Toolkit; returns tokens + user doc.

        The Firebase sign-in is the source of truth. The MongoDB profile is
        ensured (created if missing), so Google/email users always end up with
        a synced `users` document in MongoDB.
        """
        from django.conf import settings

        fb_password = password
        if email == settings.ADMIN_EMAIL and password == settings.ADMIN_PASSWORD:
            fb_password = settings.ADMIN_FIREBASE_PASSWORD
        result = firebase_service.sign_in_with_password(email, fb_password)
        uid = result["localId"]
        name = result.get("displayName") or email.split("@")[0]
        user_email = result.get("email") or email
        try:
            user_doc = self.sync_user(uid)
        except Exception as exc:  # noqa: BLE001
            logger.warning("MongoDB profile sync failed during login: %s", exc)
            user_doc = {
                "id": uid,
                "name": name,
                "email": user_email,
                "userType": "student",
                "studentId": "",
                "university": "",
                "department": "",
                "phone": "",
                "photoUrl": "",
                "fcmToken": "",
                "createdAt": None,
            }
        if user_doc.get("email") != user_email and user_email:
            try:
                _repo.update(uid, {"email": user_email, "name": user_doc.get("name") or name})
                user_doc["email"] = user_email
            except Exception as exc:  # noqa: BLE001
                logger.warning("Could not refresh user email in MongoDB: %s", exc)
        return {
            "access": result["idToken"],
            "refresh": result.get("refreshToken", ""),
            "user": user_doc,
        }

    def login_with_token(self, uid) -> dict:
        """Sync/return the MongoDB profile for a Firebase uid (Google sign-in).

        The Flutter app authenticates with Firebase Auth directly (Google
        sign-in) and then posts the uid so we create/refresh the MongoDB doc.
        """
        user_doc = self.sync_user(uid)
        return user_doc

    def get_user_doc(self, uid) -> dict:
        doc = _repo.get_by_uid(uid)
        if doc is None:
            raise NotFound("User profile not found.")
        return doc

    def sync_user(self, uid) -> dict:
        """Ensure a MongoDB user doc exists for this Firebase uid.

        Used after any Firebase Auth sign-in (email/password, Google, etc.) to
        keep the MongoDB profile in sync without touching Firestore. If the
        profile is missing it is created from the Firebase Auth record.
        """
        doc = _repo.get_by_uid(uid)
        if doc is not None:
            return doc
        name = "Student"
        email = ""
        try:
            fu = firebase_service.get_firebase_user(uid)
            email = fu.email or ""
            name = fu.display_name or (email.split("@")[0] if email else "Student")
        except Exception as exc:  # noqa: BLE001
            logger.warning("Could not fetch Firebase user %s: %s", uid, exc)
        return _repo.create(
            uid, {"name": name, "email": email, "userType": "student"}
        )

    def update_profile(self, uid, data: dict, photo_file=None):
        """Update allowed profile fields + optionally upload an avatar photo."""
        self.get_user_doc(uid)
        update = {}
        for key in ("name", "university", "department", "studentId", "phone", "photoUrl"):
            if key in data and data[key] is not None:
                update[key] = str(data[key])
        if photo_file is not None:
            update["photoUrl"] = firebase_service.upload_file("avatars", photo_file)
        if update:
            _repo.update(uid, update)
        return _repo.get_by_uid(uid)

    def save_fcm_token(self, uid, token):
        _repo.update_fcm_token(uid, token)


auth_service = AuthService()
