from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user matching the frontend `users` collection."""

    USER_TYPE_CHOICES = [
        ("student", "Student"),
        ("guardian", "Guardian"),
    ]

    user_type = models.CharField(
        max_length=20, choices=USER_TYPE_CHOICES, default="student"
    )
    firebase_uid = models.CharField(
        max_length=128, blank=True, default="", db_index=True
    )
    phone = models.CharField(max_length=20, blank=True, default="")
    student_id = models.CharField(max_length=11, blank=True, default="")
    university = models.CharField(max_length=120, blank=True, default="")
    photo_url = models.URLField(blank=True, default="")
    fcm_token = models.CharField(max_length=512, blank=True, default="")

    @property
    def handle(self) -> str:
        return "@" + self.username.lower().replace(" ", "")

    @property
    def display_name(self) -> str:
        return self.get_full_name() or self.username

    def __str__(self) -> str:
        return self.display_name
