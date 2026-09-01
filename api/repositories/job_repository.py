"""Data access for MongoDB `jobs` documents."""
from api.repositories.mongo_base import MongoRepository


class JobRepository(MongoRepository):
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
        "status": "pending",
        "createdAt": None,
    }

    def all(self, search=None):
        docs = self._list({"status": "approved"}, sort_key="createdAt", reverse=True)
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

    def admin_all(self, status=None):
        query = {}
        if status:
            query["status"] = status
        return self._list(query, sort_key="createdAt", reverse=True)

    def create(self, poster_uid, poster_name, payload: dict):
        data = {
            "userId": poster_uid,
            "posterName": poster_name,
            "status": "pending",
            "createdAt": self._now(),
        }
        data.update(payload)
        return self._insert(self._new_id(), data)

    def set_status(self, job_id, status):
        self.col().update_one({"_id": str(job_id)}, {"$set": {"status": status}})
        return self.get(job_id)

    def delete_by_author(self, author_uid):
        self.col().delete_many({"userId": author_uid})

    def delete(self, job_id):
        self.col().delete_one({"_id": str(job_id)})
