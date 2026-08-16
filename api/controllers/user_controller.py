"""Public user profile controller - GET /api/users/{uid}/."""
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from api.dtos.auth_dto import UserDto
from api.services.user_service import user_service


class UserProfileController(APIView):
    """GET /api/users/{uid}/  - another user's profile (name, photo, type)."""

    permission_classes = [IsAuthenticated]

    def get(self, request, uid):
        user = user_service.get_user(uid)
        return Response(UserDto(user).data)
