"""Health controller - checks the API + Firebase connection."""
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from api.services import firebase_service


class HealthController(APIView):
    """GET /api/health/  - liveness + Firebase (Firestore) connectivity probe."""

    permission_classes = [AllowAny]

    def get(self, request):
        info = {"status": "ok", "firebase_configured": firebase_service.is_configured()}
        if info["firebase_configured"]:
            try:
                firebase_service.get_firestore().collection("_health").limit(1).get()
                info["firestore"] = "connected"
            except Exception as exc:  # noqa: BLE001
                info["firestore"] = f"error: {exc}"
        else:
            info["firestore"] = "not_configured"
        return Response(info)
