"""Data access for MongoDB `users` documents."""
from api.repositories.mongo_base import MongoRepository


class UserRepository(MongoRepository):
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
        "isBanned": False,
        "createdAt": None,
    }

    def get_by_uid(self, uid):
        return self.get(uid)

    def all_users(self):
        return self._list(sort_key="createdAt", reverse=True)

    def set_banned(self, uid, banned: bool):
        self.col().update_one({"_id": str(uid)}, {"$set": {"isBanned": banned}})
        return self.get(uid)

    def create(self, uid, data: dict):
        payload = dict(data)
        payload.setdefault("createdAt", self._now())
        payload.setdefault("userType", "student")
        return self._insert(uid, payload)

    def update(self, uid, data: dict):
        self.col().update_one({"_id": str(uid)}, {"$set": dict(data)})
        return self.get(uid)

    def update_fcm_token(self, uid, token: str):
        self.col().update_one({"_id": str(uid)}, {"$set": {"fcmToken": token}})

    def all_fcm_tokens(self):
        docs = self.col().find({"fcmToken": {"$ne": ""}})
        return [self._doc(d).get("fcmToken") for d in docs if self._doc(d).get("fcmToken")]
