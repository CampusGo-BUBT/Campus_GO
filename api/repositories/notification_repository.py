"""Data access for MongoDB `notifications` documents."""
from api.repositories.mongo_base import MongoRepository


class NotificationRepository(MongoRepository):
    collection_name = "notifications"
    defaults = {
        "userId": "",
        "title": "",
        "body": "",
        "type": "system",
        "isRead": False,
        "createdAt": None,
    }

    def for_user(self, uid):
        return self._list({"userId": uid}, sort_key="createdAt", reverse=True)

    def get_for_user(self, uid, notification_id):
        doc = self.get(notification_id)
        if doc and doc.get("userId") != uid:
            return None
        return doc

    def unread_count(self, uid) -> int:
        docs = self.for_user(uid)
        return sum(1 for d in docs if not d.get("isRead"))

    def create(self, uid, title, body, type):
        data = {
            "userId": uid,
            "title": title,
            "body": body,
            "type": type,
            "isRead": False,
            "createdAt": self._now(),
        }
        return self._insert(self._new_id(), data)

    def mark_read(self, notification_id):
        self.col().update_one({"_id": str(notification_id)}, {"$set": {"isRead": True}})

    def mark_all_read(self, uid) -> int:
        result = self.col().update_many(
            {"userId": uid, "isRead": False}, {"$set": {"isRead": True}}
        )
        return result.modified_count
