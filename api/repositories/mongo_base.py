"""Shared base for MongoDB-backed repositories.

Mirrors the Firestore repository interface so the service layer can use either
backend. Documents are stored with `_id` and surfaced to callers with an `id`
field plus all default keys filled in.
"""
import uuid
from datetime import datetime

from api.services import mongo_service


class MongoRepository:
    collection_name = ""
    defaults = {}

    @classmethod
    def col(cls):
        return mongo_service.get_db()[cls.collection_name]

    @classmethod
    def _doc(cls, d) -> dict:
        data = dict(d) if d else {}
        doc_id = data.pop("_id", "")
        data["id"] = str(doc_id)
        for key, value in cls.defaults.items():
            data.setdefault(key, value)
        return data

    @classmethod
    def get(cls, doc_id):
        d = cls.col().find_one({"_id": str(doc_id)})
        if d is None:
            return None
        return cls._doc(d)

    @classmethod
    def _new_id(cls) -> str:
        return uuid.uuid4().hex

    @staticmethod
    def _now():
        return datetime.utcnow()

    @classmethod
    def _insert(cls, doc_id, data: dict) -> dict:
        payload = dict(data)
        payload["_id"] = str(doc_id)
        cls.col().replace_one({"_id": str(doc_id)}, payload, upsert=True)
        return cls.get(str(doc_id))

    @classmethod
    def _list(cls, query=None, sort_key="createdAt", reverse=True):
        cursor = cls.col().find(query or {})
        if sort_key:
            cursor = cursor.sort(sort_key, -1 if reverse else 1)
        return [cls._doc(d) for d in cursor]

    @classmethod
    def by_owner(cls, uid, owner_key="userId"):
        """List documents owned by a user (posts use authorId, others userId)."""
        return cls._list({owner_key: uid}, sort_key="createdAt", reverse=True)

    @classmethod
    def delete(cls, doc_id):
        cls.col().delete_one({"_id": str(doc_id)})

    @classmethod
    def update(cls, doc_id, data: dict):
        cls.col().update_one({"_id": str(doc_id)}, {"$set": dict(data)})
        return cls.get(doc_id)
