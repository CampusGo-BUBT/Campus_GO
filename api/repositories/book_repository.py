"""Data access for Firestore `books` documents."""
from datetime import datetime

from google.cloud.firestore import SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class BookRepository(FirestoreRepository):
    collection_name = "books"
    defaults = {
        "title": "",
        "author": "",
        "price": 0,
        "originalPrice": 0,
        "condition": "Good",
        "phone": "",
        "userId": "",
        "sellerName": "",
        "imageUrl": "",
        "description": "",
        "rating": 4.5,
        "reviewCount": 0,
        "createdAt": None,
    }

    def all(self, condition=None):
        ref = self.ref()
        if condition:
            ref = ref.where("condition", "==", condition)
        snapshots = ref.get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(key=lambda d: d.get("createdAt") or datetime.min, reverse=True)
        return docs

    def create(self, seller_uid, seller_name, payload: dict):
        data = {
            "userId": seller_uid,
            "sellerName": seller_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def delete(self, book_id):
        self.ref().document(book_id).delete()
