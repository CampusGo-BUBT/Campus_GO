"""Study group business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from api.repositories.study_group_repository import StudyGroupRepository
from api.repositories.user_repository import UserRepository

_repo = StudyGroupRepository()
_user_repo = UserRepository()


class StudyGroupService:
    def list_groups(self, search=None):
        return _repo.all(search=search)

    def get_group(self, group_id):
        group = _repo.get(group_id)
        if group is None:
            raise NotFound("Study group not found.")
        return group

    def create_group(self, creator_uid, data):
        user = _user_repo.get_by_uid(creator_uid) or {}
        name = user.get("name") or "Student"
        return _repo.create(creator_uid, name, dict(data))

    def join_group(self, uid, group):
        if _repo.is_member(group, uid):
            raise ValidationError("You already joined this group.")
        if group.get("maxMembers") and _repo.member_count(group) >= group["maxMembers"]:
            raise ValidationError("Group is full.")
        _repo.add_member(group["id"], uid)
        return self.get_group(group["id"])

    def leave_group(self, uid, group):
        if not _repo.is_member(group, uid):
            raise ValidationError("You are not a member of this group.")
        _repo.remove_member(group["id"], uid)
        return self.get_group(group["id"])

    def list_messages(self, group):
        return _repo.messages(group["id"])

    def send_message(self, uid, name, group, text):
        if not text.strip():
            raise ValidationError("message is required.")
        if not _repo.is_member(group, uid):
            raise PermissionDenied("Only group members can send messages.")
        return _repo.create_message(group["id"], uid, name, text.strip())

    def delete_group(self, uid, is_staff, group):
        if group.get("creatorId") != uid and not is_staff:
            raise PermissionDenied("Only the creator can delete the group.")
        _repo.delete(group["id"])

    def update_group(self, uid, is_staff, group, data):
        if group.get("creatorId") != uid and not is_staff:
            raise PermissionDenied("Only the creator can edit the group.")
        return _repo.update(group["id"], dict(data))


study_group_service = StudyGroupService()
