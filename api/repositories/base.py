"""Shared base for Firestore-backed repositories.

Every document is returned as a plain dict that includes `id` and has all known
keys filled with defaults (mirroring the Flutter models' `?? default` fallbacks)
so DTO serialization never hits a missing key.
"""
from google.cloud.firestore import ArrayRemove, ArrayUnion, SERVER_TIMESTAMP  # noqa: F401

from api.services import firebase_service


class FirestoreRepository:
    collection_name = ""
    defaults = {}

    @classmethod
    def ref(cls):
        return firebase_service.get_collection(cls.collection_name)

    @classmethod
    def _doc(cls, snapshot) -> dict:
        data = snapshot.to_dict() or {}
        data.setdefault("id", snapshot.id)
        for key, value in cls.defaults.items():
            data.setdefault(key, value)
        return data

    @classmethod
    def get(cls, doc_id):
        snapshot = cls.ref().document(doc_id).get()
        if not snapshot.exists:
            return None
        return cls._doc(snapshot)
