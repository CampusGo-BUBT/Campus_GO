"""1-to-1 conversation business logic."""
from rest_framework.exceptions import NotFound, ValidationError

from api.repositories.conversation_repository import ConversationRepository

_repo = ConversationRepository()


def conversation_id_for(first_uid, second_uid) -> str:
    return "_".join(sorted([str(first_uid), str(second_uid)]))


class ConversationService:
    def inbox(self, uid):
        return _repo.inbox(uid)

    def get_conversation(self, uid, conversation_id):
        conversation = _repo.get(conversation_id)
        if conversation is None:
            raise NotFound("Conversation not found.")
        if uid not in conversation.get("participants", []):
            raise NotFound("Conversation not found.")
        return conversation

    def send_message(self, sender_uid, sender_name, other_uid, text):
        if not text.strip():
            raise ValidationError("message is required.")
        if sender_uid == other_uid:
            raise ValidationError("You cannot message yourself.")
        conv_id = conversation_id_for(sender_uid, other_uid)
        _repo.get_or_create(conv_id)
        _repo.add_participant(conv_id, sender_uid)
        _repo.add_participant(conv_id, other_uid)
        message = _repo.create_message(conv_id, sender_uid, sender_name, text.strip())
        _repo.update_preview(conv_id, sender_uid, text.strip())
        return message

    def get_messages(self, uid, conversation):
        if uid not in conversation.get("participants", []):
            raise NotFound("Conversation not found.")
        return _repo.messages(conversation["id"])


conversation_service = ConversationService()
