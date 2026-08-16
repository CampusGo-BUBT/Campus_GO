"""Tutor controller - tuition jobs + applications."""
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.tutor_dto import TuitionApplicationDto, TutorJobDto
from api.services.tutor_service import tuition_application_service, tutor_service


class TutorController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        search = request.query_params.get("search")
        tutors = tutor_service.list_tutors(search=search)
        return Response(TutorJobDto(tutors, many=True).data)

    def retrieve(self, request, pk=None):
        tutor = tutor_service.get_tutor(pk)
        return Response(TutorJobDto(tutor).data)

    def create(self, request):
        dto = TutorJobDto(data=request.data)
        dto.is_valid(raise_exception=True)
        tutor = tutor_service.create_tutor(request.user.firebase_uid, dto.validated_data)
        return Response(TutorJobDto(tutor).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        tutor = tutor_service.get_tutor(pk)
        tutor_service.delete_tutor(request.user.firebase_uid, request.user.is_staff, tutor)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"])
    def apply(self, request, pk=None):
        tutor = tutor_service.get_tutor(pk)
        application = tutor_service.apply_for_tuition(
            request.user.firebase_uid,
            tutor,
            phone=request.data.get("phone", ""),
            note=request.data.get("note", ""),
        )
        return Response(TuitionApplicationDto(application).data, status=status.HTTP_201_CREATED)


class TuitionApplicationController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        tuition_id = request.query_params.get("tuitionId")
        applications = tuition_application_service.list_applications(
            request.user.firebase_uid, request.user.is_staff, tuition_id
        )
        return Response(TuitionApplicationDto(applications, many=True).data)
