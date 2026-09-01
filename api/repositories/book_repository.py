"""Data access for MongoDB `books` documents."""
from api.repositories.mongo_base import MongoRepository


class BookRepository(MongoRepository):
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
        query = {}
        if condition:
            query["condition"] = condition
        return self._list(query, sort_key="createdAt", reverse=True)

    def create(self, seller_uid, seller_name, payload: dict):
        data = {
            "userId": seller_uid,
            "sellerName": seller_name,
            "createdAt": self._now(),
        }
        data.update(payload)
        return self._insert(self._new_id(), data)

    def delete(self, book_id):
        self.col().delete_one({"_id": str(book_id)})
