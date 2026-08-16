"""Study group controller - groups + join/leave + group chat."""
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.study_group_dto import StudyGroupDto, StudyGroupMessageDto
from api.services.study_group_service import study_group_service
from api.services.user_service import user_service


class StudyGroupController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        search = request.query_params.get("search")
        groups = study_group_service.list_groups(search=search)
        return Response(StudyGroupDto(groups, many=True).data)

    def retrieve(self, request, pk=None):
        group = study_group_service.get_group(pk)
        return Response(StudyGroupDto(group).data)

    def create(self, request):
        dto = StudyGroupDto(data=request.data)
        dto.is_valid(raise_exception=True)
        group = study_group_service.create_group(request.user.firebase_uid, dto.validated_data)
        return Response(StudyGroupDto(group).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        group = study_group_service.get_group(pk)
        study_group_service.delete_group(request.user.firebase_uid, request.user.is_staff, group)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"])
    def join(self, request, pk=None):
        group = study_group_service.get_group(pk)
        group = study_group_service.join_group(request.user.firebase_uid, group)
        return Response(StudyGroupDto(group).data)

    @action(detail=True, methods=["post"])
    def leave(self, request, pk=None):
        group = study_group_service.get_group(pk)
        group = study_group_service.leave_group(request.user.firebase_uid, group)
        return Response(StudyGroupDto(group).data)

    @action(detail=True, methods=["get", "post"])
    def messages(self, request, pk=None):
        group = study_group_service.get_group(pk)
        if request.method == "GET":
            messages = study_group_service.list_messages(group)
            return Response(StudyGroupMessageDto(messages, many=True).data)
        user = user_service.get_user(request.user.firebase_uid)
        message = study_group_service.send_message(
            request.user.firebase_uid,
            user.get("name") or "Student",
            group,
            request.data.get("message", ""),
        )
        return Response(StudyGroupMessageDto(message).data, status=status.HTTP_201_CREATED)
