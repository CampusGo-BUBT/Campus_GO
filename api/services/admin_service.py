"""Admin dashboard + moderation business logic."""
from api.repositories.post_repository import PostRepository
from api.repositories.job_repository import JobRepository
from api.repositories.hostel_repository import HostelRepository
from api.repositories.tutor_repository import TutorRepository
from api.repositories.user_repository import UserRepository

_post_repo = PostRepository()
_job_repo = JobRepository()
_hostel_repo = HostelRepository()
_tutor_repo = TutorRepository()
_user_repo = UserRepository()

_REPOS = {
    "post": _post_repo,
    "job": _job_repo,
    "hostel": _hostel_repo,
    "tutor": _tutor_repo,
}


def _sort_key(d):
    for key in ("createdAt", "postedAt", "appliedAt"):
        v = d.get(key)
        if v:
            return v
    return 0


class AdminService:
    def is_admin(self, uid) -> bool:
        user = _user_repo.get_by_uid(uid)
        return user is not None and user.get("userType") == "admin"

    def dashboard(self) -> dict:
        return {
            "users": _user_repo.col().count_documents({}),
            "posts": _post_repo.col().count_documents({"status": "approved"}),
            "jobs": _job_repo.col().count_documents({"status": "approved"}),
            "hostels": _hostel_repo.col().count_documents({"status": "approved"}),
            "tutors": _tutor_repo.col().count_documents({"status": "approved"}),
            "pendingRequests": sum(
                r.col().count_documents({"status": "pending"}) for r in _REPOS.values()
            ),
        }

    def list_items(self, kind, status=None):
        repo = _REPOS.get(kind)
        if repo is None:
            return []
        items = repo.admin_all(status=status)
        for it in items:
            it["kind"] = kind
        return items

    def pending_items(self):
        items = []
        for kind, repo in _REPOS.items():
            for it in repo.admin_all(status="pending"):
                items.append({**it, "kind": kind})
        items.sort(key=_sort_key, reverse=True)
        return items

    def approve(self, kind, item_id):
        return _REPOS[kind].set_status(item_id, "approved")

    def reject(self, kind, item_id):
        return _REPOS[kind].set_status(item_id, "rejected")

    def delete(self, kind, item_id):
        _REPOS[kind].delete(item_id)

    def list_users(self):
        return _user_repo.all_users()

    def ban(self, uid):
        _post_repo.delete_by_author(uid)
        _job_repo.delete_by_author(uid)
        _hostel_repo.delete_by_author(uid)
        _tutor_repo.delete_by_author(uid)
        return _user_repo.set_banned(uid, True)

    def unban(self, uid):
        return _user_repo.set_banned(uid, False)


admin_service = AdminService()
