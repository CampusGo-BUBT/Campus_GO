"""Data access for MongoDB `hostels` documents."""
from api.repositories.mongo_base import MongoRepository


class HostelRepository(MongoRepository):
    collection_name = "hostels"
    defaults = {
        "name": "",
        "type": "Boys",
        "location": "",
        "rent": 0,
        "facilities": "",
        "facilitiesList": [],
        "phone": "",
        "userId": "",
        "ownerName": "",
        "gender": "Boys",
        "imageUrl": "",
        "images": [],
        "rating": 3.7,
        "reviewCount": 0,
        "distance": "",
        "description": "",
        "status": "pending",
        "createdAt": None,
    }

    def all(self, gender=None, type=None):
        docs = self._list({"status": "approved"}, sort_key="createdAt", reverse=True)
        if gender:
            docs = [d for d in docs if d.get("gender") == gender]
        if type:
            docs = [d for d in docs if d.get("type") == type]
        return docs

    def admin_all(self, status=None):
        query = {}
        if status:
            query["status"] = status
        return self._list(query, sort_key="createdAt", reverse=True)

    def create(self, owner_uid, owner_name, payload: dict):
        data = {
            "userId": owner_uid,
            "ownerName": owner_name,
            "status": "pending",
            "createdAt": self._now(),
        }
        data.update(payload)
        return self._insert(self._new_id(), data)

    def set_status(self, hostel_id, status):
        self.col().update_one({"_id": str(hostel_id)}, {"$set": {"status": status}})
        return self.get(hostel_id)

    def delete_by_author(self, author_uid):
        self.col().delete_many({"userId": author_uid})

    def delete(self, hostel_id):
        self.col().delete_one({"_id": str(hostel_id)})
