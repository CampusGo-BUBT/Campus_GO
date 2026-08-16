"""Verify Firebase connectivity for the CampusGo backend.

Usage:
    python manage.py check_firebase

Reports whether a service-account key is configured, which project it targets,
and whether Firestore is reachable. Useful after dropping a service-account
JSON into the backend directory.
"""
from django.core.management.base import BaseCommand

from api.services import firebase_service


class Command(BaseCommand):
    help = "Check Firebase Admin SDK configuration and connectivity."

    def handle(self, *args, **options):
        if not firebase_service.is_configured():
            self.stdout.write(
                self.style.WARNING(
                    "Firebase is NOT configured. Provide a service-account key:\n"
                    "  - drop it in backend/ as service-account.json (auto-discovered), or\n"
                    "  - set GOOGLE_APPLICATION_CREDENTIALS / FIREBASE_CREDENTIALS_PATH, or\n"
                    "  - set FIREBASE_SERVICE_ACCOUNT_JSON / FIREBASE_SERVICE_ACCOUNT_B64."
                )
            )
            return

        creds = firebase_service._credentials_dict()
        self.stdout.write(
            self.style.SUCCESS(f"Firebase configured: project={creds.get('project_id')}")
        )

        try:
            firebase_service.get_firestore().collection("_health").limit(1).get()
            self.stdout.write(self.style.SUCCESS("Firestore: connected"))
        except Exception as exc:  # noqa: BLE001
            self.stdout.write(self.style.ERROR(f"Firestore: error -> {exc}"))
