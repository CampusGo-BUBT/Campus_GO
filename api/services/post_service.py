"""Feed post business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied

from api.repositories.post_repository import PostRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service

_repo = PostRepository()
_user_repo = UserRepository()


class PostService:
    def list_posts(self, author_id=None, type=None):
        return _repo.all(author_id=author_id, type=type)

    def saved_posts(self, uid):
        return _repo.saved_by(uid)

    def get_post(self, post_id):
        post = _repo.get(post_id)
        if post is None:
            raise NotFound("Post not found.")
        return post

    def create_post(self, uid, data, image_file=None):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Student"
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("post_images", image_file)
        return _repo.create(
            uid, name, "@" + name.lower().replace(" ", ""), user.get("photoUrl", ""), payload
        )

    def toggle_like(self, uid, post_id, currently_liked):
        self.get_post(post_id)
        return _repo.toggle_like(post_id, uid, bool(currently_liked))

    def toggle_save(self, uid, post_id, currently_saved):
        self.get_post(post_id)
        return _repo.toggle_save(post_id, uid, bool(currently_saved))

    def delete_post(self, uid, is_staff, post):
        if post.get("authorId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own posts.")
        _repo.delete(post["id"])

    def update_post(self, uid, is_staff, post, data, image_file=None):
        if post.get("authorId") != uid and not is_staff:
            raise PermissionDenied("You can only edit your own posts.")
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("post_images", image_file)
        if not payload:
            return post
        return _repo.update(post["id"], payload)


post_service = PostService()
