"""Tuition job + application business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from api.repositories.tutor_repository import (
    TuitionApplicationRepository,
    TutorRepository,
)
from api.repositories.user_repository import UserRepository
from api.services.notification_service import notification_service

_tutor_repo = TutorRepository()
_app_repo = TuitionApplicationRepository()
_user_repo = UserRepository()


class TutorService:
    def list_tutors(self, search=None):
        return _tutor_repo.all(search=search)

    def get_tutor(self, tutor_id):
        tutor = _tutor_repo.get(tutor_id)
        if tutor is None:
            raise NotFound("Tuition post not found.")
        return tutor

    def create_tutor(self, uid, data):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Student"
        tutor = _tutor_repo.create(uid, name, dict(data))
        notification_service.broadcast("New Tuition Post", tutor.get("title", ""), type="tutor")
        return tutor

    def apply_for_tuition(self, uid, tutor, phone="", note=""):
        if _tutor_repo.has_applicant(tutor, uid):
            raise ValidationError("Already applied.")
        if tutor.get("userId") == uid:
            raise ValidationError("You cannot apply to your own tuition post.")
        user = _user_repo.get_by_uid(uid) or {}
        application = _app_repo.create(
            tutor["id"], uid, user.get("name") or "Applicant", phone or "", note or ""
        )
        _tutor_repo.add_applicant(tutor["id"], uid)
        return application

    def delete_tutor(self, uid, is_staff, tutor):
        if tutor.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own tuition posts.")
        _tutor_repo.delete(tutor["id"])


class TuitionApplicationService:
    def list_applications(self, uid, is_staff, tuition_id=None):
        qs = _app_repo.all(applicant_uid=None if is_staff else uid)
        if tuition_id:
            qs = [a for a in qs if a.get("tuitionId") == tuition_id]
        return qs


tutor_service = TutorService()
tuition_application_service = TuitionApplicationService()
