"""Data access for MongoDB `notices` documents."""
from api.repositories.mongo_base import MongoRepository


class NoticeRepository(MongoRepository):
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
        query = {}
        if category:
            query["category"] = category
        return self._list(query, sort_key="createdAt", reverse=True)

    def create(self, user_uid, author_name, payload: dict):
        data = {
            "userId": user_uid,
            "authorName": author_name,
            "createdAt": self._now(),
        }
        data.update(payload)
        return self._insert(self._new_id(), data)

    def delete(self, notice_id):
        self.col().delete_one({"_id": str(notice_id)})
