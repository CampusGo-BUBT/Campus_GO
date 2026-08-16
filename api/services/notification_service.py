"""In-app notification + FCM push business logic."""
from api.repositories.notification_repository import NotificationRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service

_repo = NotificationRepository()
_user_repo = UserRepository()

# Topic every app install subscribes to (frontend NotificationService.init()).
ALL_UPDATES_TOPIC = "all_updates"


class NotificationService:
    def list_for_user(self, uid):
        return _repo.for_user(uid)

    def unread_count(self, uid) -> int:
        return _repo.unread_count(uid)

    def mark_read(self, uid, notification_id):
        notification = _repo.get_for_user(uid, notification_id)
        if notification is None:
            return None
        _repo.mark_read(notification_id)
        notification["isRead"] = True
        return notification

    def mark_all_read(self, uid) -> int:
        return _repo.mark_all_read(uid)

    def notify_user(self, uid, title, body="", type="system", push=True):
        notification = _repo.create(uid, title, body, type)
        if push:
            user = _user_repo.get_by_uid(uid) or {}
            token = user.get("fcmToken")
            if token:
                firebase_service.send_to_token(token, title, body, {"type": type})
        return notification

    def broadcast(self, title, body="", type="system", topic=ALL_UPDATES_TOPIC):
        firebase_service.send_to_topic(topic, title, body, {"type": type})


notification_service = NotificationService()
