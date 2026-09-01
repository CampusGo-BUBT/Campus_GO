"""Book controller - list/create/delete books."""
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.book_dto import BookDto
from api.services.book_service import book_service


class BookController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        condition = request.query_params.get("condition")
        books = book_service.list_books(condition=condition)
        return Response(BookDto(books, many=True).data)

    def retrieve(self, request, pk=None):
        book = book_service.get_book(pk)
        return Response(BookDto(book).data)

    def create(self, request):
        dto = BookDto(data=request.data)
        dto.is_valid(raise_exception=True)
        image = request.FILES.get("image")
        book = book_service.create_book(request.user.firebase_uid, dto.validated_data, image_file=image)
        return Response(BookDto(book).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        book = book_service.get_book(pk)
        book_service.delete_book(request.user.firebase_uid, request.user.is_staff, book)
        return Response(status=status.HTTP_204_NO_CONTENT)

    def partial_update(self, request, pk=None):
        book = book_service.get_book(pk)
        dto = BookDto(data=request.data, partial=True)
        dto.is_valid(raise_exception=True)
        image = request.FILES.get("image")
        book = book_service.update_book(
            request.user.firebase_uid, request.user.is_staff, book,
            dto.validated_data, image_file=image,
        )
        return Response(BookDto(book).data)
