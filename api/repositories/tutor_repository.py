"""Data access for Firestore `tutors` and `tuition_applications` documents."""
from datetime import datetime

from google.cloud.firestore import ArrayUnion, SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class TutorRepository(FirestoreRepository):
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
    }

    def all(self, search=None):
        snapshots = self.ref().order_by("postedAt", direction="DESCENDING").get()
        docs = [self._doc(s) for s in snapshots]
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

    def create(self, user_uid, poster_name, payload: dict):
        data = {
            "userId": user_uid,
            "posterName": poster_name,
            "applicants": [],
            "postedAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        doc = self.get(ref.id)
        if not doc.get("jobId"):
            job_id = f"544{ref.id[:3]}1"
            self.ref().document(ref.id).update({"jobId": job_id})
            doc = self.get(ref.id)
        return doc

    def has_applicant(self, tutor: dict, uid) -> bool:
        return uid in tutor.get("applicants", [])

    def add_applicant(self, tutor_id, uid):
        self.ref().document(tutor_id).update({"applicants": ArrayUnion([uid])})

    def delete(self, tutor_id):
        self.ref().document(tutor_id).delete()


class TuitionApplicationRepository(FirestoreRepository):
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
        ref = self.ref()
        if applicant_uid:
            ref = ref.where("applicantId", "==", applicant_uid)
        snapshots = ref.get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(key=lambda d: d.get("appliedAt") or datetime.min, reverse=True)
        return docs

    def create(self, tuition_id, applicant_uid, applicant_name, phone, note):
        data = {
            "tuitionId": tuition_id,
            "applicantId": applicant_uid,
            "applicantName": applicant_name,
            "applicantPhone": phone,
            "note": note,
            "status": "pending",
            "appliedAt": SERVER_TIMESTAMP,
        }
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)
