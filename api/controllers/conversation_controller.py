"""Conversation controller - inbox + direct messages."""
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.conversation_dto import ConversationDto, DirectMessageDto
from api.services.conversation_service import conversation_service
from api.services.user_service import user_service


class ConversationController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        conversations = conversation_service.inbox(request.user.firebase_uid)
        return Response(ConversationDto(conversations, many=True).data)

    def retrieve(self, request, pk=None):
        conversation = conversation_service.get_conversation(request.user.firebase_uid, pk)
        return Response(ConversationDto(conversation).data)

    @action(detail=False, methods=["post"])
    def send(self, request):
        other = user_service.get_user(request.data.get("otherUserId", ""))
        me = user_service.get_user(request.user.firebase_uid)
        message = conversation_service.send_message(
            request.user.firebase_uid,
            me.get("name") or "Student",
            other["id"],
            request.data.get("message", ""),
        )
        return Response(DirectMessageDto(message).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get", "post"])
    def messages(self, request, pk=None):
        conversation = conversation_service.get_conversation(request.user.firebase_uid, pk)
        if request.method == "GET":
            messages = conversation_service.get_messages(request.user.firebase_uid, conversation)
            return Response(DirectMessageDto(messages, many=True).data)
        other_uid = next(
            (p for p in conversation.get("participants", []) if p != request.user.firebase_uid),
            None,
        )
        if other_uid is None:
            return Response(
                {"error": "No recipient in this conversation."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        me = user_service.get_user(request.user.firebase_uid)
        message = conversation_service.send_message(
            request.user.firebase_uid,
            me.get("name") or "Student",
            other_uid,
            request.data.get("message", ""),
        )
        return Response(DirectMessageDto(message).data, status=status.HTTP_201_CREATED)
