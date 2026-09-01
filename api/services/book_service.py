"""Book marketplace business logic."""
from rest_framework.exceptions import NotFound, PermissionDenied

from api.repositories.book_repository import BookRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service

_repo = BookRepository()
_user_repo = UserRepository()


class BookService:
    def list_books(self, condition=None):
        return _repo.all(condition=condition)

    def get_book(self, book_id):
        book = _repo.get(book_id)
        if book is None:
            raise NotFound("Book not found.")
        return book

    def create_book(self, uid, data, image_file=None):
        user = _user_repo.get_by_uid(uid) or {}
        name = user.get("name") or "Student"
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("book_images", image_file)
        return _repo.create(uid, name, payload)

    def delete_book(self, uid, is_staff, book):
        if book.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only delete your own books.")
        _repo.delete(book["id"])

    def update_book(self, uid, is_staff, book, data, image_file=None):
        if book.get("userId") != uid and not is_staff:
            raise PermissionDenied("You can only edit your own books.")
        payload = dict(data)
        if image_file:
            payload["imageUrl"] = firebase_service.upload_file("book_images", image_file)
        return _repo.update(book["id"], payload)


book_service = BookService()
