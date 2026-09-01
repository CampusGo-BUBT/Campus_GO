"""Auth DTOs - validate request input and shape Firestore `users` doc responses.

The user profile lives in Firestore `users/{uid}` with these keys:
name, email, userType, studentId, university, phone, photoUrl, fcmToken, createdAt.
"""
from rest_framework import serializers


class UserDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    name = serializers.CharField(read_only=True, default="")
    email = serializers.CharField(read_only=True, default="")
    userType = serializers.CharField(read_only=True, default="student")
    studentId = serializers.CharField(read_only=True, default="")
    university = serializers.CharField(read_only=True, default="")
    department = serializers.CharField(read_only=True, default="")
    phone = serializers.CharField(read_only=True, default="")
    photoUrl = serializers.CharField(read_only=True, default="", allow_null=True)
    fcmToken = serializers.CharField(read_only=True, default="", allow_null=True)
    isBanned = serializers.BooleanField(read_only=True, default=False)
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)


class RegisterDto(serializers.Serializer):
    name = serializers.CharField(required=True, max_length=150)
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, min_length=6)
    userType = serializers.ChoiceField(
        choices=["student", "guardian"], default="student"
    )
    studentId = serializers.CharField(required=False, allow_blank=True, max_length=20)
    university = serializers.CharField(required=False, allow_blank=True, max_length=120)
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)

    def validate(self, attrs):
        if attrs.get("userType") == "student":
            student_id = attrs.get("studentId", "")
            if len(student_id) != 11:
                raise serializers.ValidationError(
                    {"studentId": "Student ID must be exactly 11 digits."}
                )
        return attrs


class LoginDto(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True)
