"""Book DTO - maps a Firestore `books` document.

Keys: title, author, price, originalPrice, condition, phone, userId, sellerName,
imageUrl, description, rating, reviewCount, createdAt.
"""
from rest_framework import serializers


class BookDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    title = serializers.CharField(required=True, max_length=200)
    author = serializers.CharField(required=True, max_length=200)
    price = serializers.FloatField(min_value=0)
    originalPrice = serializers.FloatField(min_value=0, required=False, default=0)
    condition = serializers.ChoiceField(
        choices=["New", "Good", "Midlevel"], default="Good"
    )
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    userId = serializers.CharField(read_only=True, default="")
    sellerName = serializers.CharField(read_only=True, default="")
    imageUrl = serializers.CharField(read_only=True, default="", allow_null=True)
    description = serializers.CharField(required=False, allow_blank=True)
    rating = serializers.FloatField(read_only=True, default=4.5)
    reviewCount = serializers.IntegerField(read_only=True, default=0)
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
