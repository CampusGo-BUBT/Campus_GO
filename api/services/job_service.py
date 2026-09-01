"""Job listing business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied

from api.repositories.job_repository import JobRepository
from api.repositories.user_repository import UserRepository
from api.services.notification_service import notification_service

_repo = JobRepository()
_user_repo = UserRepository()


class JobService:
    def list_jobs(self, search=None):
        return _repo.all(search=search)

    def get_job(self, job_id):
        job = _repo.get(job_id)
        if job is None:
            raise NotFound("Job not found.")
        return job

    def create_job(self, uid, data):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Recruiter"
        job = _repo.create(uid, name, dict(data))
        notification_service.broadcast("New Job Opportunity", job.get("title", ""), type="job")
        return job

    def delete_job(self, uid, is_staff, job):
        if job.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own jobs.")
        _repo.delete(job["id"])

    def update_job(self, uid, is_staff, job, data):
        if job.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only edit your own jobs.")
        return _repo.update(job["id"], dict(data))


job_service = JobService()
