"""Notice business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied

from api.repositories.notice_repository import NoticeRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service
from api.services.notification_service import notification_service

_repo = NoticeRepository()
_user_repo = UserRepository()


class NoticeService:
    def list_notices(self, category=None):
        return _repo.all(category=category)

    def get_notice(self, notice_id):
        notice = _repo.get(notice_id)
        if notice is None:
            raise NotFound("Notice not found.")
        return notice

    def create_notice(self, uid, data, attachment_file=None):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Admin"
        payload = dict(data)
        if attachment_file:
            payload["attachmentName"] = attachment_file.name
            payload["attachmentUrl"] = firebase_service.upload_file("notice_files", attachment_file)
        notice = _repo.create(uid, name, payload)
        notification_service.broadcast(
            f"{notice.get('category', 'Notice')} Notice",
            notice.get("title", ""),
            type="notice",
        )
        return notice

    def delete_notice(self, uid, is_staff, notice):
        if notice.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own notices.")
        _repo.delete(notice["id"])


notice_service = NoticeService()
