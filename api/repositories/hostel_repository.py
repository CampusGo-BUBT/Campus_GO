"""Data access for Firestore `hostels` documents."""
from google.cloud.firestore import SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class HostelRepository(FirestoreRepository):
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
        "createdAt": None,
    }

    def all(self, gender=None, type=None):
        snapshots = self.ref().order_by("createdAt", direction="DESCENDING").get()
        docs = [self._doc(s) for s in snapshots]
        if gender:
            docs = [d for d in docs if d.get("gender") == gender]
        if type:
            docs = [d for d in docs if d.get("type") == type]
        return docs

    def create(self, owner_uid, owner_name, payload: dict):
        data = {
            "userId": owner_uid,
            "ownerName": owner_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def delete(self, hostel_id):
        self.ref().document(hostel_id).delete()
