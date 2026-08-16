"""Notification DTO - maps a Firestore `notifications` document.

Keys: userId, title, body, type, isRead, createdAt.
"""
from rest_framework import serializers


class NotificationDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    userId = serializers.CharField(read_only=True, default="")
    title = serializers.CharField(read_only=True, default="")
    body = serializers.CharField(read_only=True, default="")
    type = serializers.CharField(read_only=True, default="system")
    isRead = serializers.BooleanField(read_only=True, default=False)
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
