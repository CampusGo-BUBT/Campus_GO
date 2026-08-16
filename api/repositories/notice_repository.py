"""Data access for Firestore `notices` documents."""
from datetime import datetime

from google.cloud.firestore import SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class NoticeRepository(FirestoreRepository):
    collection_name = "notices"
    defaults = {
        "title": "",
        "content": "",
        "category": "Important",
        "dateStr": "",
        "attachmentName": "",
        "attachmentUrl": "",
        "userId": "",
        "authorName": "",
        "createdAt": None,
    }

    def all(self, category=None):
        ref = self.ref()
        if category:
            ref = ref.where("category", "==", category)
        snapshots = ref.get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(key=lambda d: d.get("createdAt") or datetime.min, reverse=True)
        return docs

    def create(self, user_uid, author_name, payload: dict):
        data = {
            "userId": user_uid,
            "authorName": author_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def delete(self, notice_id):
        self.ref().document(notice_id).delete()
