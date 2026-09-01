"""Notice controller - list/create/delete notices."""
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.notice_dto import NoticeDto
from api.services.notice_service import notice_service


class NoticeController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        category = request.query_params.get("category")
        notices = notice_service.list_notices(category=category)
        return Response(NoticeDto(notices, many=True).data)

    def retrieve(self, request, pk=None):
        notice = notice_service.get_notice(pk)
        return Response(NoticeDto(notice).data)

    def create(self, request):
        dto = NoticeDto(data=request.data)
        dto.is_valid(raise_exception=True)
        attachment = request.FILES.get("attachment")
        notice = notice_service.create_notice(
            request.user.firebase_uid, dto.validated_data, attachment_file=attachment
        )
        return Response(NoticeDto(notice).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        notice = notice_service.get_notice(pk)
        notice_service.delete_notice(request.user.firebase_uid, request.user.is_staff, notice)
        return Response(status=status.HTTP_204_NO_CONTENT)

    def partial_update(self, request, pk=None):
        notice = notice_service.get_notice(pk)
        dto = NoticeDto(data=request.data, partial=True)
        dto.is_valid(raise_exception=True)
        attachment = request.FILES.get("attachment")
        notice = notice_service.update_notice(
            request.user.firebase_uid, request.user.is_staff, notice,
            dto.validated_data, attachment_file=attachment,
        )
        return Response(NoticeDto(notice).data)
