"""Health controller - checks the API + MongoDB connection."""
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from api.services import firebase_service, mongo_service


class HealthController(APIView):
    """GET /api/health/  - liveness + Mongo/Firebase connectivity probe."""

    permission_classes = [AllowAny]

    def get(self, request):
        info = {
            "status": "ok",
            "firebase_configured": firebase_service.is_configured(),
        }

        # MongoDB is the live data store.
        if mongo_service.is_configured():
            try:
                mongo_service.get_db().command("ping")
                info["mongo"] = "connected"
            except Exception as exc:  # noqa: BLE001
                info["mongo"] = f"error: {exc}"
        else:
            info["mongo"] = "not_configured"

        # Firebase is kept for auth / storage only.
        if info["firebase_configured"]:
            info["firestore"] = "read-only (data now served from MongoDB)"
        else:
            info["firestore"] = "not_configured"

        return Response(info)
