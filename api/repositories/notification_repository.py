"""Data access for Firestore `notifications` documents."""
from google.cloud.firestore import SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class NotificationRepository(FirestoreRepository):
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
        snapshots = self.ref().where("userId", "==", uid).get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(
            key=lambda d: d.get("createdAt"),
            reverse=True,
        )
        return docs

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
            "createdAt": SERVER_TIMESTAMP,
        }
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def mark_read(self, notification_id):
        self.ref().document(notification_id).update({"isRead": True})

    def mark_all_read(self, uid) -> int:
        docs = self.for_user(uid)
        count = 0
        for d in docs:
            if not d.get("isRead"):
                self.ref().document(d["id"]).update({"isRead": True})
                count += 1
        return count
