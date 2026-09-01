"""Data access for MongoDB `tutors` and `tuition_applications` documents."""
from api.repositories.mongo_base import MongoRepository


class TutorRepository(MongoRepository):
    collection_name = "tutors"
    defaults = {
        "jobId": "",
        "title": "",
        "tutoringType": "Home Tutoring",
        "location": "",
        "subLocation": "",
        "medium": "",
        "studentClass": "",
        "preferredTutor": "",
        "subject": "",
        "daysPerWeek": "",
        "salary": "",
        "hourlyRate": 6000,
        "requirements": "",
        "phone": "",
        "userId": "",
        "posterName": "",
        "postedAt": None,
        "applicants": [],
        "status": "pending",
    }

    def all(self, search=None):
        docs = self._list({"status": "approved"}, sort_key="postedAt", reverse=True)
        if search:
            q = str(search).lower()
            docs = [
                d
                for d in docs
                if q in d.get("title", "").lower()
                or q in d.get("subject", "").lower()
                or q in d.get("location", "").lower()
                or q in d.get("medium", "").lower()
                or q in d.get("studentClass", "").lower()
            ]
        return docs

    def admin_all(self, status=None):
        query = {}
        if status:
            query["status"] = status
        return self._list(query, sort_key="postedAt", reverse=True)

    def create(self, user_uid, poster_name, payload: dict):
        data = {
            "userId": user_uid,
            "posterName": poster_name,
            "applicants": [],
            "status": "pending",
            "postedAt": self._now(),
        }
        data.update(payload)
        doc_id = self._new_id()
        doc = self._insert(doc_id, data)
        if not doc.get("jobId"):
            job_id = f"544{doc_id[:3]}1"
            self.col().update_one({"_id": doc_id}, {"$set": {"jobId": job_id}})
            doc = self.get(doc_id)
        return doc

    def set_status(self, tutor_id, status):
        self.col().update_one({"_id": str(tutor_id)}, {"$set": {"status": status}})
        return self.get(tutor_id)

    def has_applicant(self, tutor: dict, uid) -> bool:
        return uid in tutor.get("applicants", [])

    def add_applicant(self, tutor_id, uid):
        self.col().update_one({"_id": str(tutor_id)}, {"$addToSet": {"applicants": uid}})

    def delete_by_author(self, author_uid):
        self.col().delete_many({"userId": author_uid})

    def delete(self, tutor_id):
        self.col().delete_one({"_id": str(tutor_id)})


class TuitionApplicationRepository(MongoRepository):
    collection_name = "tuition_applications"
    defaults = {
        "tuitionId": "",
        "applicantId": "",
        "applicantName": "",
        "applicantPhone": "",
        "note": "",
        "status": "pending",
        "appliedAt": None,
    }

    def all(self, applicant_uid=None):
        query = {}
        if applicant_uid:
            query["applicantId"] = applicant_uid
        return self._list(query, sort_key="appliedAt", reverse=True)

    def create(self, tuition_id, applicant_uid, applicant_name, phone, note):
        data = {
            "tuitionId": tuition_id,
            "applicantId": applicant_uid,
            "applicantName": applicant_name,
            "applicantPhone": phone,
            "note": note,
            "status": "pending",
            "appliedAt": self._now(),
        }
        return self._insert(self._new_id(), data)
