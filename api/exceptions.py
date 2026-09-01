"""Custom DRF exception handling.

Maps Google Cloud (Firestore) exceptions to clean HTTP responses so the
frontend gets a readable message instead of a bare 500 when the Firestore
free-tier quota is exhausted or the backend is temporarily unreachable.
"""
from rest_framework.views import exception_handler


def campusgo_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        return response

    # Firestore / Google Cloud errors are not DRF exceptions.
    try:
        from google.api_core import exceptions as google_exceptions

        if isinstance(exc, google_exceptions.GoogleAPIError):
            from rest_framework.response import Response

            return Response(
                {"detail": f"Firestore is temporarily unavailable: {exc}"},
                status=503,
            )
    except ImportError:
        pass

    return None
