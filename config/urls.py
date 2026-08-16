from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.db import connection
from django.http import JsonResponse
from django.urls import include, path

from api.services import firebase_service


def index(request):
    """Root route - a human/automation-friendly liveness + connectivity check."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        database = "connected"
    except Exception as exc:  # noqa: BLE001
        database = f"error: {exc}"

    if firebase_service.is_configured():
        try:
            firebase_service.get_firestore().collection("_health").limit(1).get()
            firestore = "connected"
        except Exception as exc:  # noqa: BLE001
            firestore = f"error: {exc}"
    else:
        firestore = "not_configured"

    return JsonResponse(
        {
            "message": "CampusGo backend is running and connected to the database.",
            "status": "ok",
            "database": database,
            "firestore": firestore,
        }
    )


urlpatterns = [
    path("", index, name="index"),
    path("admin/", admin.site.urls),
    path("api/", include("api.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
