"""Authentication business logic (Firebase Auth + Firestore `users` docs)."""
from rest_framework.exceptions import NotFound

from api.repositories.user_repository import UserRepository
from api.services import firebase_service

_repo = UserRepository()


class AuthService:
    def register(self, name, email, password, user_type, student_id="", university="", phone=""):
        """Create a Firebase Auth account + Firestore `users/{uid}` profile."""
        uid = firebase_service.create_firebase_user(email, password, name)
        return _repo.create(
            uid,
            {
                "name": name,
                "email": email,
                "userType": user_type,
                "studentId": student_id or "",
                "university": university or "",
                "phone": phone or "",
            },
        )

    def login(self, email, password):
        """Sign in via Firebase Identity Toolkit; returns tokens + user doc."""
        result = firebase_service.sign_in_with_password(email, password)
        uid = result["localId"]
        user_doc = _repo.get_by_uid(uid)
        if user_doc is None:
            user_doc = _repo.create(
                uid,
                {
                    "name": result.get("displayName") or email.split("@")[0],
                    "email": result.get("email") or email,
                    "userType": "student",
                },
            )
        return {
            "access": result["idToken"],
            "refresh": result.get("refreshToken", ""),
            "user": user_doc,
        }

    def get_user_doc(self, uid) -> dict:
        doc = _repo.get_by_uid(uid)
        if doc is None:
            raise NotFound("User profile not found.")
        return doc

    def update_profile(self, uid, data: dict, photo_file=None):
        """Update allowed profile fields + optionally upload an avatar photo."""
        self.get_user_doc(uid)
        update = {}
        for key in ("name", "university", "department", "studentId", "phone", "photoUrl"):
            if key in data and data[key] is not None:
                update[key] = str(data[key])
        if photo_file is not None:
            update["photoUrl"] = firebase_service.upload_file("avatars", photo_file)
        if update:
            _repo.update(uid, update)
        return _repo.get_by_uid(uid)

    def save_fcm_token(self, uid, token):
        _repo.update_fcm_token(uid, token)


auth_service = AuthService()
