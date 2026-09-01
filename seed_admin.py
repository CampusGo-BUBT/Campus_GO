"""Seed the static admin account (Firebase Auth + MongoDB).

Usage: python seed_admin.py
Email: admin@gmail.com   Password: 1  (Firebase minimum is 6 chars, so the
Firebase Auth account uses "111111"; MongoDB stores the requested "1" for the
static reference, and login accepts "1" for admin via the MongoDB check.)
"""
import os
from datetime import datetime

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from api.services import firebase_service, mongo_service  # noqa: E402

EMAIL = "admin@gmail.com"
FIREBASE_PASSWORD = "111111"  # Firebase Auth requires >= 6 chars
NAME = "Admin"

uid = None
try:
    uid = firebase_service.create_firebase_user(EMAIL, FIREBASE_PASSWORD, NAME)
    print("Created Firebase Auth admin account.")
except Exception as exc:  # noqa: BLE001
    print("Firebase admin may already exist:", exc)
    try:
        from firebase_admin import auth
        u = auth.get_user_by_email(EMAIL, app=firebase_service._require_app())
        uid = u.uid
    except Exception as exc2:  # noqa: BLE001
        print("Could not resolve admin uid:", exc2)

if uid:
    db = mongo_service.get_db()
    db.users.replace_one(
        {"_id": uid},
        {
            "name": NAME,
            "email": EMAIL,
            "password": "1",
            "userType": "admin",
            "studentId": "",
            "university": "",
            "department": "",
            "phone": "",
            "photoUrl": "",
            "fcmToken": "",
            "isBanned": False,
            "createdAt": datetime.utcnow(),
        },
        upsert=True,
    )
    print(f"Admin seeded in MongoDB with uid={uid}")
else:
    print("Admin seeding skipped (no uid).")
