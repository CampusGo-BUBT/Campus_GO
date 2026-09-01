"""Hostel DTO - maps a Firestore `hostels` document.

Keys: name, type, location, rent, facilities, facilitiesList[], phone, userId,
ownerName, gender, imageUrl, images[], rating, reviewCount, distance, description,
createdAt.
"""
from rest_framework import serializers


class HostelDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    name = serializers.CharField(required=True, max_length=200)
    type = serializers.ChoiceField(
        choices=["Boys", "Girls", "Family"], default="Boys"
    )
    location = serializers.CharField(required=True, max_length=200)
    rent = serializers.FloatField(min_value=0)
    facilities = serializers.CharField(required=False, allow_blank=True, max_length=500)
    facilitiesList = serializers.ListField(
        child=serializers.CharField(), required=False, default=list
    )
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    userId = serializers.CharField(read_only=True, default="")
    ownerName = serializers.CharField(read_only=True, default="")
    gender = serializers.ChoiceField(
        choices=["Boys", "Girls", "Family"], default="Boys"
    )
    imageUrl = serializers.CharField(required=False, allow_blank=True, allow_null=True, default="")
    images = serializers.ListField(
        child=serializers.CharField(), required=False, default=list
    )
    rating = serializers.FloatField(read_only=True, default=3.7)
    reviewCount = serializers.IntegerField(read_only=True, default=0)
    distance = serializers.CharField(required=False, allow_blank=True, max_length=200)
    description = serializers.CharField(required=False, allow_blank=True)
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
