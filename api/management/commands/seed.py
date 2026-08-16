"""Seed demo data into Firebase (Firestore + Auth) and create a Django admin user.

Usage:
    python manage.py seed

Firestore/Auth seeding requires Firebase credentials (see .env). If they are
missing the command only creates the local Django superuser and prints a hint.
"""
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from api.repositories.book_repository import BookRepository
from api.repositories.hostel_repository import HostelRepository
from api.repositories.job_repository import JobRepository
from api.repositories.notice_repository import NoticeRepository
from api.repositories.post_repository import PostRepository
from api.repositories.study_group_repository import StudyGroupRepository
from api.repositories.tutor_repository import TutorRepository
from api.repositories.user_repository import UserRepository
from api.services import firebase_service

User = get_user_model()


class Command(BaseCommand):
    help = "Seed CampusGo demo data into Firebase + create a local admin user."

    def handle(self, *args, **options):
        admin, _ = User.objects.get_or_create(
            username="admin",
            defaults={"email": "admin@campusgo.app", "is_staff": True, "is_superuser": True},
        )
        admin.set_password("password123")
        admin.save()
        self.stdout.write(self.style.SUCCESS("Local Django admin created (admin / password123)."))

        if not firebase_service.is_configured():
            self.stdout.write(
                self.style.WARNING(
                    "Firebase is not configured - skipping Firestore seeding. "
                    "Set GOOGLE_APPLICATION_CREDENTIALS / FIREBASE_CREDENTIALS_PATH."
                )
            )
            return

        try:
            uid = firebase_service.create_firebase_user(
                "student@campusgo.app", "password123", "Arafat Hossain"
            )
        except Exception as exc:  # noqa: BLE001
            self.stdout.write(self.style.WARNING(f"Could not create Firebase user: {exc}"))
            return

        UserRepository().create(
            uid,
            {
                "name": "Arafat Hossain",
                "email": "student@campusgo.app",
                "userType": "student",
                "studentId": "12345678901",
                "university": "BUBT",
                "phone": "01700000000",
            },
        )
        self.stdout.write("Seeded Firebase user.")

        PostRepository().create(
            uid,
            "Arafat Hossain",
            "@arafathossain",
            "",
            {"caption": "Mid-semester results are out!", "type": "announcement"},
        )
        BookRepository().create(
            uid, "Arafat Hossain", {"title": "Data Structures and Algorithms", "author": "Narasimha Karumanchi", "price": 350, "originalPrice": 650, "condition": "Good"}
        )
        JobRepository().create(
            uid, "Arafat Hossain", {"title": "UI/UX Designer", "company": "Creative IT Ltd.", "location": "Dhaka", "salary": "Tk15,000 - 25,000"}
        )
        HostelRepository().create(
            uid, "Arafat Hossain", {"name": "Green View Boys Hostel", "type": "Boys", "location": "Jahar Town, BUBT", "rent": 4500, "gender": "Boys"}
        )
        NoticeRepository().create(
            uid, "Arafat Hossain", {"title": "Midterm Exam Routine 2026", "category": "Exams", "content": "Midterm exams start next month."}
        )
        TutorRepository().create(
            uid, "Arafat Hossain", {"title": "Tutor Needed For Mathematics", "subject": "Mathematics", "location": "Mirpur-2, Dhaka", "salary": "6,000 Tk/Month"}
        )
        StudyGroupRepository().create(
            uid, "Arafat Hossain", {"name": "CSE-300 Study Squad", "subject": "Software Development Project", "location": "Library", "maxMembers": 8}
        )

        self.stdout.write(self.style.SUCCESS("Firebase seed complete."))
