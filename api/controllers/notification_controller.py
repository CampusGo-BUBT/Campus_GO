"""Notification controller - in-app notifications (Firestore `notifications`)."""
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.dtos.notification_dto import NotificationDto
from api.services.notification_service import notification_service


class NotificationController(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        notifications = notification_service.list_for_user(request.user.firebase_uid)
        return Response(NotificationDto(notifications, many=True).data)

    def retrieve(self, request, pk=None):
        notification = notification_service.mark_read(request.user.firebase_uid, pk)
        if notification is None:
            return Response({"detail": "Notification not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(NotificationDto(notification).data)

    @action(detail=True, methods=["post"])
    def read(self, request, pk=None):
        notification = notification_service.mark_read(request.user.firebase_uid, pk)
        if notification is None:
            return Response({"detail": "Notification not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(NotificationDto(notification).data)

    @action(detail=False, methods=["post"])
    def read_all(self, request):
        updated = notification_service.mark_all_read(request.user.firebase_uid)
        return Response({"updated": updated})

    @action(detail=False, methods=["get"])
    def unread_count(self, request):
        count = notification_service.unread_count(request.user.firebase_uid)
        return Response({"count": count})
