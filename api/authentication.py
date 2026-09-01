"""DRF authentication that trusts Firebase Auth ID tokens.

The Flutter app signs in with Firebase Auth and sends its ID token as
`Authorization: Bearer <idToken>`. This class verifies it with the Admin SDK,
then maps the Firebase UID to a local Django user (for admin / audit only).
"""
from django.contrib.auth import get_user_model
from rest_framework import HTTP_HEADER_ENCODING, exceptions
from rest_framework.authentication import BaseAuthentication, get_authorization_header

from api.repositories.user_repository import UserRepository
from api.services import firebase_service


class FirebaseTokenAuthentication(BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        auth = get_authorization_header(request).split()
        if not auth or auth[0].lower() != self.keyword.lower().encode():
            return None
        if len(auth) == 1:
            raise exceptions.AuthenticationFailed(
                "Invalid token header. No credentials provided."
            )
        if len(auth) > 2:
            raise exceptions.AuthenticationFailed(
                "Invalid token header. Token string should not contain spaces."
            )
        token = auth[1].decode(HTTP_HEADER_ENCODING)
        return self._authenticate_credentials(request, token)

    def _authenticate_credentials(self, request, token):
        try:
            decoded = firebase_service.verify_id_token(token)
        except Exception as exc:  # noqa: BLE001
            raise exceptions.AuthenticationFailed(
                "Invalid or expired Firebase token."
            ) from exc

        uid = decoded["uid"]

        banned = False
        try:
            user_doc = UserRepository().get(uid)
            banned = bool(user_doc and user_doc.get("isBanned"))
        except Exception:  # noqa: BLE001
            pass
        if banned:
            raise exceptions.AuthenticationFailed("This account has been banned.")

        User = get_user_model()
        name = decoded.get("name", "")
        user, _ = User.objects.get_or_create(
            username=f"fb_{uid}",
            defaults={
                "email": decoded.get("email") or "",
                "first_name": name.split(" ")[0] if name else "",
                "last_name": name.split(" ", 1)[1] if " " in name else "",
            },
        )
        if user.firebase_uid != uid:
            user.firebase_uid = uid
            user.save(update_fields=["firebase_uid"])
        return (user, token)

    def authenticate_header(self, request):
        return self.keyword
