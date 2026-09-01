"""Data access for MongoDB `posts` documents."""
from api.repositories.mongo_base import MongoRepository

# Types that require admin approval before appearing in the public feed.
MODERATED_TYPES = {"job", "hostel", "tuition"}


class PostRepository(MongoRepository):
    collection_name = "posts"
    defaults = {
        "authorId": "",
        "authorName": "",
        "authorHandle": "",
        "authorPhotoUrl": "",
        "caption": "",
        "imageUrl": "",
        "type": "general",
        "likedBy": [],
        "savedBy": [],
        "commentCount": 0,
        "status": "approved",
        "createdAt": None,
    }

    def all(self, author_id=None, type=None):
        query = {"status": "approved"}
        if author_id:
            query["authorId"] = author_id
        if type:
            query["type"] = type
        return self._list(query, sort_key="createdAt", reverse=True)

    def admin_all(self, status=None, type=None):
        query = {}
        if status:
            query["status"] = status
        if type:
            query["type"] = type
        return self._list(query, sort_key="createdAt", reverse=True)

    def saved_by(self, uid):
        return self._list(
            {"savedBy": uid, "status": "approved"},
            sort_key="createdAt",
            reverse=True,
        )

    def create(self, author_uid, author_name, author_handle, author_photo_url, payload: dict):
        data = {
            "authorId": author_uid,
            "authorName": author_name,
            "authorHandle": author_handle,
            "authorPhotoUrl": author_photo_url or "",
            "likedBy": [],
            "savedBy": [],
            "commentCount": 0,
            "createdAt": self._now(),
        }
        data.update(payload)
        ptype = (data.get("type") or "general").lower()
        data["status"] = "pending" if ptype in MODERATED_TYPES else "approved"
        return self._insert(self._new_id(), data)

    def set_status(self, post_id, status):
        self.col().update_one({"_id": str(post_id)}, {"$set": {"status": status}})
        return self.get(post_id)

    def toggle_like(self, post_id, uid, currently_liked: bool):
        op = "$pull" if currently_liked else "$addToSet"
        self.col().update_one({"_id": str(post_id)}, {op: {"likedBy": uid}})
        return self.get(post_id)

    def toggle_save(self, post_id, uid, currently_saved: bool):
        op = "$pull" if currently_saved else "$addToSet"
        self.col().update_one({"_id": str(post_id)}, {op: {"savedBy": uid}})
        return self.get(post_id)

    def delete_by_author(self, author_uid):
        self.col().delete_many({"authorId": author_uid})

    def delete(self, post_id):
        self.col().delete_one({"_id": str(post_id)})
