"""Data access for Firestore `study_groups` docs + `messages` subcollection."""
from google.cloud.firestore import ArrayRemove, ArrayUnion, SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class StudyGroupRepository(FirestoreRepository):
    collection_name = "study_groups"
    defaults = {
        "name": "",
        "subject": "",
        "description": "",
        "location": "",
        "time": "",
        "maxMembers": 5,
        "members": [],
        "creatorId": "",
        "creatorName": "",
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
                if q in d.get("name", "").lower()
                or q in d.get("subject", "").lower()
                or q in d.get("location", "").lower()
            ]
        return docs

    def create(self, creator_uid, creator_name, payload: dict):
        data = {
            "creatorId": creator_uid,
            "creatorName": creator_name,
            "members": [creator_uid],
            "createdAt": SERVER_TIMESTAMP,
        }
        data.update(payload)
        ref = self.ref().document()
        ref.set(data)
        return self.get(ref.id)

    def add_member(self, group_id, uid):
        self.ref().document(group_id).update({"members": ArrayUnion([uid])})

    def remove_member(self, group_id, uid):
        self.ref().document(group_id).update({"members": ArrayRemove([uid])})

    def is_member(self, group: dict, uid) -> bool:
        return uid in group.get("members", [])

    def member_count(self, group: dict) -> int:
        return len(group.get("members", []))

    def messages(self, group_id):
        snapshots = (
            self.ref().document(group_id).collection("messages").order_by("createdAt").get()
        )
        return [self._message(s) for s in snapshots]

    def create_message(self, group_id, sender_uid, sender_name, text: str):
        data = {
            "message": text,
            "senderId": sender_uid,
            "senderName": sender_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        ref = self.ref().document(group_id).collection("messages").document()
        ref.set(data)
        snapshot = ref.get()
        return self._message(snapshot)

    @staticmethod
    def _message(snapshot) -> dict:
        data = snapshot.to_dict() or {}
        data.setdefault("id", snapshot.id)
        data.setdefault("message", "")
        data.setdefault("senderId", "")
        data.setdefault("senderName", "")
        data.setdefault("createdAt", None)
        return data

    def delete(self, group_id):
        self.ref().document(group_id).delete()
