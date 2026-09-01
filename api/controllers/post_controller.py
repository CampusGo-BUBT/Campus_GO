"""Post controller - feed CRUD, like/save, saved feed."""
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.post_dto import PostDto
from api.services.post_service import post_service


class PostController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        author_id = request.query_params.get("authorId")
        post_type = request.query_params.get("type")
        posts = post_service.list_posts(author_id=author_id, type=post_type)
        return Response(PostDto(posts, many=True).data)

    @action(detail=False, methods=["get"])
    def saved(self, request):
        posts = post_service.saved_posts(request.user.firebase_uid)
        return Response(PostDto(posts, many=True).data)

    def create(self, request):
        dto = PostDto(data=request.data)
        dto.is_valid(raise_exception=True)
        image = request.FILES.get("image")
        post = post_service.create_post(
            request.user.firebase_uid, dto.validated_data, image_file=image
        )
        return Response(PostDto(post).data, status=status.HTTP_201_CREATED)

    def retrieve(self, request, pk=None):
        post = post_service.get_post(pk)
        return Response(PostDto(post).data)

    def destroy(self, request, pk=None):
        post = post_service.get_post(pk)
        post_service.delete_post(request.user.firebase_uid, request.user.is_staff, post)
        return Response(status=status.HTTP_204_NO_CONTENT)

    def partial_update(self, request, pk=None):
        post = post_service.get_post(pk)
        dto = PostDto(data=request.data, partial=True)
        dto.is_valid(raise_exception=True)
        image = request.FILES.get("image")
        post = post_service.update_post(
            request.user.firebase_uid, request.user.is_staff, post,
            dto.validated_data, image_file=image,
        )
        return Response(PostDto(post).data)

    @action(detail=True, methods=["post"])
    def like(self, request, pk=None):
        post = post_service.toggle_like(
            request.user.firebase_uid, pk, request.data.get("currentlyLiked", False)
        )
        return Response({"likedBy": post.get("likedBy", [])})

    @action(detail=True, methods=["post"])
    def save(self, request, pk=None):
        post = post_service.toggle_save(
            request.user.firebase_uid, pk, request.data.get("currentlySaved", False)
        )
        return Response({"savedBy": post.get("savedBy", [])})
