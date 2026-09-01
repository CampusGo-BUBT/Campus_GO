"""Notice DTO - maps a Firestore `notices` document.

Keys: title, content, category, dateStr, attachmentName, attachmentUrl, userId,
authorName, createdAt.
"""
from rest_framework import serializers


class NoticeDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    title = serializers.CharField(required=True, max_length=250)
    content = serializers.CharField(required=False, allow_blank=True)
    category = serializers.ChoiceField(
        choices=["Important", "Academic", "Exams", "Events"], default="Important"
    )
    dateStr = serializers.CharField(required=False, allow_blank=True, max_length=60)
    attachmentName = serializers.CharField(required=False, allow_blank=True, max_length=200)
    attachmentUrl = serializers.CharField(required=False, allow_blank=True, allow_null=True, default="")
    userId = serializers.CharField(read_only=True, default="")
    authorName = serializers.CharField(read_only=True, default="")
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
