"""Replicate Firestore data into MongoDB (one-way sync).

Usage:
    python manage.py migrate_to_mongo

Copies every Firestore collection (plus the `messages` subcollections under
`study_groups` and `conversations`) into MongoDB. Re-runnable: each document is
upserted by its Firestore id, so running it again just refreshes the copy.

Requires MONGODB_URI in .env (see mongo_service.py).
"""
from datetime import datetime

from django.core.management.base import BaseCommand

from api.services import firebase_service, mongo_service

# Top-level Firestore collections -> MongoDB collection names (same name).
TOP_LEVEL = [
    "users",
    "posts",
    "books",
    "jobs",
    "hostels",
    "notices",
    "tutors",
    "tuition_applications",
    "study_groups",
    "conversations",
    "notifications",
]

# (parent_collection, subcollection, mongo_collection, foreign_key)
SUBCOLLECTIONS = [
    ("study_groups", "messages", "study_group_messages", "groupId"),
    ("conversations", "messages", "conversation_messages", "conversationId"),
]


def _to_bson(value):
    """Convert Firestore values to BSON-safe plain Python values."""
    if isinstance(value, datetime):
        return value
    if isinstance(value, dict):
        return {k: _to_bson(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_to_bson(v) for v in value]
    try:
        from google.cloud.firestore import GeoPoint

        if isinstance(value, GeoPoint):
            return {"lat": value.latitude, "lng": value.longitude}
    except ImportError:
        pass
    return value


class Command(BaseCommand):
    help = "Replicate all Firestore data into MongoDB."

    def handle(self, *args, **options):
        if not mongo_service.is_configured():
            self.stderr.write(
                self.style.ERROR(
                    "MONGODB_URI is not configured. Add it to backend/.env first."
                )
            )
            return

        try:
            db = mongo_service.get_db()
        except Exception as exc:  # noqa: BLE001
            self.stderr.write(self.style.ERROR(f"MongoDB connection failed: {exc}"))
            return

        fs = firebase_service.get_firestore()

        for name in TOP_LEVEL:
            self._copy_collection(fs, db, name, name)

        for parent, sub, mongo_name, fk in SUBCOLLECTIONS:
            self._copy_subcollection(fs, db, parent, sub, mongo_name, fk)

        self.stdout.write(self.style.SUCCESS("MongoDB replication complete."))

    def _copy_collection(self, fs, db, src_name, dst_name):
        try:
            snapshots = fs.collection(src_name).get()
        except Exception as exc:  # noqa: BLE001
            self.stderr.write(f"{src_name}: ERROR reading Firestore -> {exc}")
            return
        col = db[dst_name]
        count = 0
        for s in snapshots:
            data = _to_bson(s.to_dict() or {})
            data["_id"] = s.id
            data["id"] = s.id
            col.replace_one({"_id": s.id}, data, upsert=True)
            count += 1
        self.stdout.write(f"{dst_name}: {count} docs")

    def _copy_subcollection(self, fs, db, parent, sub, mongo_name, fk):
        try:
            parents = fs.collection(parent).get()
        except Exception as exc:  # noqa: BLE001
            self.stderr.write(f"{parent}/{sub}: ERROR -> {exc}")
            return
        col = db[mongo_name]
        count = 0
        for p in parents:
            try:
                msgs = p.reference.collection(sub).get()
            except Exception as exc:  # noqa: BLE001
                self.stderr.write(f"{parent}/{sub}: ERROR -> {exc}")
                continue
            for m in msgs:
                data = _to_bson(m.to_dict() or {})
                data["_id"] = m.id
                data["id"] = m.id
                data[fk] = p.id
                col.replace_one({"_id": m.id}, data, upsert=True)
                count += 1
        self.stdout.write(f"{mongo_name}: {count} docs")
