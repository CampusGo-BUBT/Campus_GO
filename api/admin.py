from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CampusGoUserAdmin(UserAdmin):
    list_display = ("username", "email", "first_name", "last_name", "user_type", "is_staff")
    list_filter = ("user_type", "is_staff", "is_active")
    fieldsets = UserAdmin.fieldsets + (
        (
            "CampusGo",
            {"fields": ("user_type", "phone", "student_id", "university", "photo_url", "fcm_token")},
        ),
    )
