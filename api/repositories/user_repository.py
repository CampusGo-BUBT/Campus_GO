"""Data access for Firestore `users/{uid}` documents."""
from google.cloud.firestore import SERVER_TIMESTAMP

from api.services import firebase_service
from api.repositories.base import FirestoreRepository


class UserRepository(FirestoreRepository):
    collection_name = "users"
    defaults = {
        "name": "",
        "email": "",
        "userType": "student",
        "studentId": "",
        "university": "",
        "department": "",
        "phone": "",
        "photoUrl": "",
        "fcmToken": "",
        "createdAt": None,
    }

    def get_by_uid(self, uid):
        return self.get(uid)

    def create(self, uid, data: dict):
        payload = dict(data)
        payload.setdefault("createdAt", SERVER_TIMESTAMP)
        payload.setdefault("userType", "student")
        self.ref().document(uid).set(payload)
        return self.get(uid)

    def update(self, uid, data: dict):
        self.ref().document(uid).update(dict(data))
        return self.get(uid)

    def update_fcm_token(self, uid, token: str):
        self.ref().document(uid).update({"fcmToken": token})

    def all_fcm_tokens(self):
        docs = self.ref().where("fcmToken", "!=", "").get()
        return [d.to_dict().get("fcmToken") for d in docs if d.to_dict().get("fcmToken")]
