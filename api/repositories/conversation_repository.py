"""Data access for Firestore `conversations` docs + `messages` subcollection."""
from google.cloud.firestore import ArrayUnion, SERVER_TIMESTAMP

from api.repositories.base import FirestoreRepository


class ConversationRepository(FirestoreRepository):
    collection_name = "conversations"
    defaults = {
        "participants": [],
        "lastMessage": "",
        "lastMessageTime": None,
        "lastSenderId": "",
        "createdAt": None,
    }

    def inbox(self, uid):
        snapshots = self.ref().where("participants", "array_contains", uid).get()
        docs = [self._doc(s) for s in snapshots]
        docs.sort(
            key=lambda d: d.get("lastMessageTime") or d.get("createdAt"),
            reverse=True,
        )
        return docs

    def get_or_create(self, conversation_id):
        ref = self.ref().document(conversation_id)
        snapshot = ref.get()
        if snapshot.exists:
            return self._doc(snapshot)
        ref.set(
            {
                "participants": [],
                "lastMessage": "",
                "lastMessageTime": SERVER_TIMESTAMP,
                "lastSenderId": "",
                "createdAt": SERVER_TIMESTAMP,
            }
        )
        return self._doc(ref.get())

    def add_participant(self, conversation_id, uid):
        self.ref().document(conversation_id).update(
            {"participants": ArrayUnion([uid])}
        )

    def update_preview(self, conversation_id, sender_uid, text: str):
        self.ref().document(conversation_id).update(
            {
                "lastMessage": text,
                "lastSenderId": sender_uid,
                "lastMessageTime": SERVER_TIMESTAMP,
            }
        )

    def messages(self, conversation_id):
        snapshots = (
            self.ref().document(conversation_id).collection("messages").order_by("createdAt").get()
        )
        return [self._message(s) for s in snapshots]

    def create_message(self, conversation_id, sender_uid, sender_name, text: str):
        data = {
            "message": text,
            "senderId": sender_uid,
            "senderName": sender_name,
            "createdAt": SERVER_TIMESTAMP,
        }
        ref = self.ref().document(conversation_id).collection("messages").document()
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
