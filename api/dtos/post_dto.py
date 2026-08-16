"""Post DTO - maps a Firestore `posts` document to/from the API.

Document keys: authorId, authorName, authorHandle, authorPhotoUrl, caption,
imageUrl, createdAt, likedBy[], savedBy[], commentCount, type.
"""
from rest_framework import serializers


class PostDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    authorId = serializers.CharField(read_only=True, default="")
    authorName = serializers.CharField(read_only=True, default="")
    authorHandle = serializers.CharField(read_only=True, default="")
    authorPhotoUrl = serializers.CharField(read_only=True, default="", allow_null=True)
    caption = serializers.CharField(required=False, allow_blank=True)
    imageUrl = serializers.CharField(read_only=True, default="", allow_null=True)
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
    likedBy = serializers.ListField(child=serializers.CharField(), read_only=True, default=list)
    savedBy = serializers.ListField(child=serializers.CharField(), read_only=True, default=list)
    commentCount = serializers.IntegerField(read_only=True, default=0)
    type = serializers.CharField(required=False, default="general")
