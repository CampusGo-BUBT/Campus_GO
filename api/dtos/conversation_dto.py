"""Conversation DTOs - Firestore `conversations` docs + `messages` subcollection.

conversations keys: participants[], lastMessage, lastMessageTime, lastSenderId.
messages keys: message, senderId, senderName, createdAt.
"""
from rest_framework import serializers


class ConversationDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    participants = serializers.ListField(
        child=serializers.CharField(), read_only=True, default=list
    )
    lastMessage = serializers.CharField(read_only=True, default="")
    lastMessageTime = serializers.DateTimeField(read_only=True, allow_null=True)
    lastSenderId = serializers.CharField(read_only=True, default="")


class DirectMessageDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    message = serializers.CharField(read_only=True, default="")
    senderId = serializers.CharField(read_only=True, default="")
    senderName = serializers.CharField(read_only=True, default="")
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
