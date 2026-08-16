"""User lookup business logic."""
from rest_framework.exceptions import NotFound

from api.repositories.user_repository import UserRepository

_repo = UserRepository()


class UserService:
    def get_user(self, uid) -> dict:
        user = _repo.get_by_uid(uid)
        if user is None:
            raise NotFound("User not found.")
        return user


user_service = UserService()
