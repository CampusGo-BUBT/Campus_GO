"""Data access for MongoDB `conversations` documents (messages embedded)."""
from api.repositories.mongo_base import MongoRepository


class ConversationRepository(MongoRepository):
    collection_name = "conversations"
    defaults = {
        "participants": [],
        "lastMessage": "",
        "lastMessageTime": None,
        "lastSenderId": "",
        "createdAt": None,
    }

    def inbox(self, uid):
        return self._list(
            {"participants": uid}, sort_key="lastMessageTime", reverse=True
        )

    def get_or_create(self, conversation_id):
        existing = self.get(conversation_id)
        if existing is not None:
            return existing
        return self._insert(
            conversation_id,
            {
                "participants": [],
                "lastMessage": "",
                "lastMessageTime": self._now(),
                "lastSenderId": "",
                "createdAt": self._now(),
                "messages": [],
            },
        )

    def add_participant(self, conversation_id, uid):
        self.col().update_one(
            {"_id": str(conversation_id)}, {"$addToSet": {"participants": uid}}
        )

    def update_preview(self, conversation_id, sender_uid, text: str):
        self.col().update_one(
            {"_id": str(conversation_id)},
            {
                "$set": {
                    "lastMessage": text,
                    "lastSenderId": sender_uid,
                    "lastMessageTime": self._now(),
                }
            },
        )

    def messages(self, conversation_id):
        doc = self.col().find_one({"_id": str(conversation_id)})
        if doc is None:
            return []
        return [self._message(m) for m in doc.get("messages", [])]

    def create_message(self, conversation_id, sender_uid, sender_name, text: str):
        msg = {
            "id": self._new_id(),
            "message": text,
            "senderId": sender_uid,
            "senderName": sender_name,
            "createdAt": self._now(),
        }
        self.col().update_one(
            {"_id": str(conversation_id)}, {"$push": {"messages": msg}}
        )
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
