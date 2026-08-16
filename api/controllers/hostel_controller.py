"""Hostel controller - list/create/delete hostels."""
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.hostel_dto import HostelDto
from api.services.hostel_service import hostel_service


class HostelController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        gender = request.query_params.get("gender")
        type = request.query_params.get("type")
        hostels = hostel_service.list_hostels(gender=gender, type=type)
        return Response(HostelDto(hostels, many=True).data)

    def retrieve(self, request, pk=None):
        hostel = hostel_service.get_hostel(pk)
        return Response(HostelDto(hostel).data)

    def create(self, request):
        dto = HostelDto(data=request.data)
        dto.is_valid(raise_exception=True)
        image = request.FILES.get("image")
        hostel = hostel_service.create_hostel(
            request.user.firebase_uid, dto.validated_data, image_file=image
        )
        return Response(HostelDto(hostel).data, status=status.HTTP_201_CREATED)

    def destroy(self, request, pk=None):
        hostel = hostel_service.get_hostel(pk)
        hostel_service.delete_hostel(request.user.firebase_uid, request.user.is_staff, hostel)
        return Response(status=status.HTTP_204_NO_CONTENT)
