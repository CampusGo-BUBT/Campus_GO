"""Job controller - list/create/delete job listings."""
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.job_dto import JobDto
from api.services.job_service import job_service


class JobController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        search = request.query_params.get("search")
        jobs = job_service.list_jobs(search=search)
        return Response(JobDto(jobs, many=True).data)

    def retrieve(self, request, pk=None):
        job = job_service.get_job(pk)
        return Response(JobDto(job).data)

    def create(self, request):
        dto = JobDto(data=request.data)
        dto.is_valid(raise_exception=True)
        job = job_service.create_job(request.user.firebase_uid, dto.validated_data)
        return Response(JobDto(job).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        job = job_service.get_job(pk)
        job_service.delete_job(request.user.firebase_uid, request.user.is_staff, job)
        return Response(status=status.HTTP_204_NO_CONTENT)
