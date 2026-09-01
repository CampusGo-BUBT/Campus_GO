"""Hostel listing business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied

from api.repositories.hostel_repository import HostelRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service

_repo = HostelRepository()
_user_repo = UserRepository()


class HostelService:
    def list_hostels(self, gender=None, type=None):
        return _repo.all(gender=gender, type=type)

    def get_hostel(self, hostel_id):
        hostel = _repo.get(hostel_id)
        if hostel is None:
            raise NotFound("Hostel not found.")
        return hostel

    def create_hostel(self, uid, data, image_file=None):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Owner"
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("hostel_images", image_file)
        return _repo.create(uid, name, payload)

    def delete_hostel(self, uid, is_staff, hostel):
        if hostel.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own hostels.")
        _repo.delete(hostel["id"])

    def update_hostel(self, uid, is_staff, hostel, data, image_file=None):
        if hostel.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only edit your own hostels.")
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("hostel_images", image_file)
        return _repo.update(hostel["id"], payload)


hostel_service = HostelService()
