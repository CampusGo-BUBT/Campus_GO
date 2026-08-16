"""Auth controller - register/login/me/FCM token, backed by Firebase Auth."""
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from api.dtos.auth_dto import LoginDto, RegisterDto, UserDto
from api.services.auth_service import auth_service


class RegisterController(APIView):
    """POST /api/auth/register/
    Creates a Firebase Auth account + Firestore `users/{uid}` profile.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        dto = RegisterDto(data=request.data)
        dto.is_valid(raise_exception=True)
        try:
            user_doc = auth_service.register(
                name=dto.validated_data["name"],
                email=dto.validated_data["email"],
                password=dto.validated_data["password"],
                user_type=dto.validated_data.get("userType", "student"),
                student_id=dto.validated_data.get("studentId", ""),
                university=dto.validated_data.get("university", ""),
                phone=dto.validated_data.get("phone", ""),
            )
        except (ValueError, RuntimeError) as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(UserDto(user_doc).data, status=status.HTTP_201_CREATED)


class LoginController(APIView):
    """POST /api/auth/login/  - email + password -> { access, refresh, user }.

    `access` is a Firebase ID token; send it as `Authorization: Bearer <access>`.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        dto = LoginDto(data=request.data)
        dto.is_valid(raise_exception=True)
        try:
            result = auth_service.login(
                dto.validated_data["email"], dto.validated_data["password"]
            )
        except (ValueError, RuntimeError) as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(
            {
                "access": result["access"],
                "refresh": result["refresh"],
                "user": UserDto(result["user"]).data,
            },
            status=status.HTTP_200_OK,
        )


class MeController(APIView):
    """GET /api/auth/user/  - current user profile (from Firestore)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user_doc = auth_service.get_user_doc(request.user.firebase_uid)
        return Response(UserDto(user_doc).data)


class UpdateTokenController(APIView):
    """PATCH /api/auth/user/token/  - store the device FCM push token."""

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        token = request.data.get("fcm_token") or request.data.get("fcmToken", "")
        auth_service.save_fcm_token(request.user.firebase_uid, token)
        return Response({"ok": True})


class UpdateProfileController(APIView):
    """PATCH /api/auth/user/profile/
    Update the Firestore user profile. Accepts name, university, studentId,
    phone and an optional multipart `photo` file (uploaded to Storage).
    """

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        photo = request.FILES.get("photo")
        user_doc = auth_service.update_profile(
            request.user.firebase_uid,
            request.data,
            photo_file=photo,
        )
        return Response(UserDto(user_doc).data)
