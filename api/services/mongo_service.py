"""MongoDB client for the CampusGo data replica.

Uses a lazy singleton so the connection is only opened when a command actually
needs MongoDB (keeps the rest of the app unaffected when MONGODB_URI is empty).
"""
import logging

logger = logging.getLogger(__name__)

_client = None
_db = None


def is_configured() -> bool:
    from django.conf import settings

    return bool(settings.MONGODB_URI)


def get_client():
    global _client
    if _client is not None:
        return _client
    from django.conf import settings

    if not settings.MONGODB_URI:
        raise RuntimeError("MONGODB_URI is not configured.")
    import pymongo

    _client = pymongo.MongoClient(
        settings.MONGODB_URI,
        serverSelectionTimeoutMS=8000,
    )
    return _client


def get_db():
    global _db
    if _db is not None:
        return _db
    from django.conf import settings

    name = settings.MONGODB_DB_NAME or "campusgo"
    _db = get_client()[name]
    return _db
