"""Data access for Firestore `jobs` documents."""
from google.cloud.firestore import SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class JobRepository(FirestoreRepository):
    collection_name = "jobs"
    defaults = {
        "title": "",
        "company": "",
        "location": "",
        "salary": "",
        "type": "Full Time",
        "workplaceType": "On-site",
        "description": "",
        "requirements": [],
        "benefits": [],
        "applicantCount": 0,
        "contactEmail": "",
        "phone": "",
        "userId": "",
        "posterName": "",
        "createdAt": None,
    }

    def all(self, search=None):
        snapshots = self.ref().order_by("createdAt", direction="DESCENDING").get()
        docs = [self._doc(s) for s in snapshots]
        if search:
            q = str(search).lower()
            docs = [
                d
                for d in docs
                if q in d.get("title", "").lower()
                or q in d.get("company", "").lower()
                or q in d.get("location", "").lower()
            ]
        return docs

    def create(self, poster_uid, poster_name, payload: dict):
        data = {
            "userId": poster_uid,
            "posterName": poster_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def delete(self, job_id):
        self.ref().document(job_id).delete()
