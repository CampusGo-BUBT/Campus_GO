"""Data access for Firestore `posts` documents."""
from datetime import datetime

from google.cloud.firestore import ArrayRemove, ArrayUnion, SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class PostRepository(FirestoreRepository):
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
        "createdAt": None,
    }

    def all(self, author_id=None):
        ref = self.ref()
        if author_id:
            ref = ref.where("authorId", "==", author_id)
        snapshots = ref.get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(key=lambda d: d.get("createdAt") or datetime.min, reverse=True)
        return docs

    def saved_by(self, uid):
        snapshots = self.ref().where("savedBy", "array_contains", uid).get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(
            key=lambda d: d.get("createdAt") or datetime.min,
            reverse=True,
        )
        return docs

    def create(self, author_uid, author_name, author_handle, author_photo_url, payload: dict):
        data = {
            "authorId": author_uid,
            "authorName": author_name,
            "authorHandle": author_handle,
            "authorPhotoUrl": author_photo_url or "",
            "likedBy": [],
            "savedBy": [],
            "commentCount": 0,
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def toggle_like(self, post_id, uid, currently_liked: bool):
        op = ArrayRemove([uid]) if currently_liked else ArrayUnion([uid])
        self.ref().document(post_id).update({"likedBy": op})
        return self.get(post_id)

    def toggle_save(self, post_id, uid, currently_saved: bool):
        op = ArrayRemove([uid]) if currently_saved else ArrayUnion([uid])
        self.ref().document(post_id).update({"savedBy": op})
        return self.get(post_id)

    def delete(self, post_id):
        self.ref().document(post_id).delete()
