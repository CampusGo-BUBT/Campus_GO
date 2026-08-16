"""Study group DTOs - Firestore `study_groups` docs + `messages` subcollection.

study_groups keys: name, subject, description, location, time, maxMembers,
members[], creatorId, creatorName, createdAt.
messages keys: message, senderId, senderName, createdAt.
"""
from rest_framework import serializers


class StudyGroupDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    name = serializers.CharField(required=True, max_length=200)
    subject = serializers.CharField(required=True, max_length=150)
    description = serializers.CharField(required=False, allow_blank=True)
    location = serializers.CharField(required=False, allow_blank=True, max_length=200)
    time = serializers.CharField(required=False, allow_blank=True, max_length=100)
    maxMembers = serializers.IntegerField(required=False, default=5)
    members = serializers.ListField(
        child=serializers.CharField(), read_only=True, default=list
    )
    creatorId = serializers.CharField(read_only=True, default="")
    creatorName = serializers.CharField(read_only=True, default="")
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)


class StudyGroupMessageDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    message = serializers.CharField(read_only=True, default="")
    senderId = serializers.CharField(read_only=True, default="")
    senderName = serializers.CharField(read_only=True, default="")
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
