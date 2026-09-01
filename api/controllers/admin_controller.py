"""Admin controllers - dashboard, moderation (approve/reject/delete), users."""
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from api.dtos.auth_dto import UserDto
from api.services.admin_service import admin_service


def _require_admin(request):
    if not admin_service.is_admin(request.user.firebase_uid):
        return Response(
            {"detail": "Admin access required."}, status=status.HTTP_403_FORBIDDEN
        )
    return None


class AdminDashboardController(APIView):
    """GET /api/admin/dashboard/  - summary counts."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = _require_admin(request)
        if err:
            return err
        return Response(admin_service.dashboard())


class AdminItemsController(APIView):
    """GET /api/admin/items/?kind=&status=  - list items (all or pending)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = _require_admin(request)
        if err:
            return err
        kind = request.query_params.get("kind")
        status_filter = request.query_params.get("status")
        if kind:
            items = admin_service.list_items(kind, status=status_filter)
        else:
            items = admin_service.pending_items()
        return Response(items)


class AdminModerateController(APIView):
    """POST /api/admin/moderate/<kind>/<item_id>/<action>/
    where action is approve | reject | delete.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, kind, item_id, action):
        err = _require_admin(request)
        if err:
            return err
        if action == "approve":
            admin_service.approve(kind, item_id)
        elif action == "reject":
            admin_service.reject(kind, item_id)
        elif action == "delete":
            admin_service.delete(kind, item_id)
        else:
            return Response({"detail": "Unknown action."}, status=400)
        return Response({"ok": True})


class AdminUsersController(APIView):
    """GET /api/admin/users/ and POST /api/admin/users/<uid>/<action>/."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        err = _require_admin(request)
        if err:
            return err
        return Response(UserDto(admin_service.list_users(), many=True).data)

    def post(self, request, uid, action):
        err = _require_admin(request)
        if err:
            return err
        if action == "ban":
            admin_service.ban(uid)
        elif action == "unban":
            admin_service.unban(uid)
        else:
            return Response({"detail": "Unknown action."}, status=400)
        return Response({"ok": True})
