"""Data access for MongoDB `study_groups` documents (messages embedded)."""
from api.repositories.mongo_base import MongoRepository


class StudyGroupRepository(MongoRepository):
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
        docs = self._list(sort_key="createdAt", reverse=True)
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
            "messages": [],
            "createdAt": self._now(),
        }
        data.update(payload)
        return self._insert(self._new_id(), data)

    def add_member(self, group_id, uid):
        self.col().update_one({"_id": str(group_id)}, {"$addToSet": {"members": uid}})

    def remove_member(self, group_id, uid):
        self.col().update_one({"_id": str(group_id)}, {"$pull": {"members": uid}})

    def is_member(self, group: dict, uid) -> bool:
        return uid in group.get("members", [])

    def member_count(self, group: dict) -> int:
        return len(group.get("members", []))

    def messages(self, group_id):
        doc = self.col().find_one({"_id": str(group_id)})
        if doc is None:
            return []
        return [self._message(m) for m in doc.get("messages", [])]

    def create_message(self, group_id, sender_uid, sender_name, text: str):
        msg = {
            "id": self._new_id(),
            "message": text,
            "senderId": sender_uid,
            "senderName": sender_name,
            "createdAt": self._now(),
        }
        self.col().update_one({"_id": str(group_id)}, {"$push": {"messages": msg}})
        return self._message(msg)

    @staticmethod
    def _message(data) -> dict:
        m = dict(data) if data else {}
        m.setdefault("id", "")
        m.setdefault("message", "")
        m.setdefault("senderId", "")
        m.setdefault("senderName", "")
        m.setdefault("createdAt", None)
        return m

    def delete(self, group_id):
        self.col().delete_one({"_id": str(group_id)})
