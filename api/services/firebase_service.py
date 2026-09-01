"""
Firebase Admin integration - the backend gateway to Firebase.

The Flutter app authenticates with Firebase Auth and sends its ID token to this
API as `Authorization: Bearer <idToken>`. The API:

  * verifies that ID token (firebase_admin.auth.verify_id_token)
  * reads / writes Firestore via the Admin SDK (source of truth = Firestore)
  * uploads files to Firebase Storage
  * sends FCM push notifications

Configure credentials with ONE of:
    GOOGLE_APPLICATION_CREDENTIALS=<path to service-account.json>
    FIREBASE_CREDENTIALS_PATH=<path to service-account.json>
    FIREBASE_SERVICE_ACCOUNT_JSON=<raw service-account JSON>
    FIREBASE_SERVICE_ACCOUNT_B64=<base64 of service-account JSON>

Login via email/password uses the Firebase Identity Toolkit REST API, which
only needs the web API key (FIREBASE_WEB_API_KEY) - no service account.
"""
import base64
import json
import logging
import os
import uuid

import requests

logger = logging.getLogger(__name__)

_firebase_app = None

IDENTITY_TOOLKIT_SIGNIN = (
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
)


def _discover_service_account_files():
    """Look for a service-account key dropped into the backend directory.

    Makes setup as simple as "copy the downloaded JSON into backend/" without
    touching .env. Explicit env vars always take precedence (see below).
    """
    from pathlib import Path

    try:
        from django.conf import settings

        base = Path(settings.BASE_DIR)
    except Exception:  # noqa: BLE001 - fall back to this file's location
        base = Path(__file__).resolve().parents[2]

    exact = [base / "service-account.json", base / "firebase-adminsdk.json"]
    patterns = [
        "*-adminsdk*.json",
        "*adminsdk*.json",
        "serviceAccount*.json",
        "service-account*.json",
        "*service*account*.json",
    ]
    discovered = []
    for pattern in patterns:
        discovered.extend(base.glob(pattern))

    ordered = [p for p in exact if p.is_file()]
    for p in sorted(set(discovered)):
        if p not in ordered:
            ordered.append(p)
    return ordered


def _credentials_dict():
    path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or os.getenv(
        "FIREBASE_CREDENTIALS_PATH"
    )
    if path and os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)

    for candidate in _discover_service_account_files():
        try:
            with open(candidate, encoding="utf-8") as fh:
                data = json.load(fh)
            if data.get("type") == "service_account":
                logger.info("Using service-account key: %s", candidate)
                return data
        except (OSError, json.JSONDecodeError) as exc:  # noqa: BLE001
            logger.warning("Could not read %s: %s", candidate, exc)

    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if raw:
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            pass

    b64 = os.getenv("FIREBASE_SERVICE_ACCOUNT_B64")
    if b64:
        try:
            return json.loads(base64.b64decode(b64).decode("utf-8"))
        except Exception:
            pass
    return None


def is_configured() -> bool:
    return _credentials_dict() is not None


def get_firebase_app():
    """Lazily initialise the Firebase Admin SDK (singleton)."""
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        logger.warning("firebase-admin is not installed - Firebase integration disabled.")
        return None

    creds = _credentials_dict()
    if creds is None:
        logger.warning("Firebase credentials not configured - Firebase integration disabled.")
        return None

    try:
        _firebase_app = firebase_admin.initialize_app(
            credentials.Certificate(creds),
            options={
                "projectId": creds.get("project_id"),
                "storageBucket": os.getenv(
                    "FIREBASE_STORAGE_BUCKET", f"{creds.get('project_id')}.appspot.com"
                ),
            },
        )
    except ValueError:
        _firebase_app = firebase_admin.get_app()
    return _firebase_app


def _require_app():
    app = get_firebase_app()
    if app is None:
        raise RuntimeError(
            "Firebase is not configured. Set GOOGLE_APPLICATION_CREDENTIALS or "
            "FIREBASE_CREDENTIALS_PATH / FIREBASE_SERVICE_ACCOUNT_JSON."
        )
    return app


# ---------------------------------------------------------------------------
# Firestore
# ---------------------------------------------------------------------------
def get_firestore():
    from firebase_admin import firestore

    return firestore.client(_require_app())


def get_collection(name):
    return get_firestore().collection(name)


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
def get_storage_bucket():
    from firebase_admin import storage

    return storage.bucket(app=_require_app())


def upload_file(folder: str, file_obj, content_type: str = None) -> str:
    """Save an uploaded file and return a public URL.

    Uploads to Firebase Storage (persistent across deploys) so files are
    visible to every user. Falls back to the local disk (settings.MEDIA_ROOT)
    when Firebase credentials are not configured, e.g. during local dev.
    """
    from urllib.parse import quote

    from django.conf import settings

    ext = os.path.splitext(getattr(file_obj, "name", "") or "")[1] or ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    blob_path = f"{folder}/{filename}"
    content_type = content_type or getattr(file_obj, "content_type", None)

    app = get_firebase_app()
    if app is None:
        media_dir = settings.MEDIA_ROOT / folder
        media_dir.mkdir(parents=True, exist_ok=True)
        dest = media_dir / filename
        with open(dest, "wb") as fh:
            for chunk in file_obj.chunks():
                fh.write(chunk)
        base = (settings.MEDIA_BASE_URL or "").rstrip("/")
        media_url = (settings.MEDIA_URL or "media").strip("/") or "media"
        return f"{base}/{media_url}/{folder}/{filename}"

    from firebase_admin import storage

    bucket = storage.bucket(app=app)
    blob = bucket.blob(blob_path)
    token = uuid.uuid4().hex
    blob.metadata = {"firebaseStorageDownloadTokens": token}
    file_obj.seek(0)
    blob.upload_from_file(file_obj, content_type=content_type)

    encoded = quote(blob_path, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{encoded}"
        f"?alt=media&token={token}"
    )


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
def verify_id_token(id_token: str) -> dict:
    """Verify a Firebase ID token, returning its claims dict."""
    from firebase_admin import auth

    return auth.verify_id_token(id_token, app=_require_app())


def create_firebase_user(email: str, password: str, name: str = "") -> str:
    """Create a Firebase Auth account, returning the new uid."""
    from firebase_admin import auth

    user = auth.create_user(
        email=email, password=password, display_name=name, app=_require_app()
    )
    return user.uid


def get_firebase_user(uid: str):
    """Fetch a Firebase Auth user record by uid (used for profile sync)."""
    from firebase_admin import auth

    return auth.get_user(uid, app=_require_app())


def sign_in_with_password(email: str, password: str) -> dict:
    """Sign in with the Firebase Identity Toolkit REST API.

    Returns {"idToken", "refreshToken", "localId", "email", ...}.
    Only needs FIREBASE_WEB_API_KEY - no service account required.
    """
    from django.conf import settings

    api_key = settings.FIREBASE_WEB_API_KEY
    if not api_key:
        raise RuntimeError("FIREBASE_WEB_API_KEY is not configured.")
    response = requests.post(
        IDENTITY_TOOLKIT_SIGNIN,
        params={"key": api_key},
        json={
            "email": email,
            "password": password,
            "returnSecureToken": True,
        },
        timeout=15,
    )
    if response.status_code == 400:
        raise ValueError("Invalid email or password.")
    response.raise_for_status()
    return response.json()


# ---------------------------------------------------------------------------
# FCM push notifications
# ---------------------------------------------------------------------------
def send_to_token(fcm_token: str, title: str, body: str = "", data: dict | None = None):
    from firebase_admin import messaging

    if get_firebase_app() is None or not fcm_token:
        return None
    message = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(title=title, body=body),
        data={str(k): str(v) for k, v in (data or {}).items()},
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(sound="default"))
        ),
    )
    try:
        return messaging.send(message, app=_require_app())
    except Exception as exc:  # noqa: BLE001
        logger.warning("FCM send_to_token failed: %s", exc)
        return None


def send_to_topic(topic: str, title: str, body: str = "", data: dict | None = None):
    from firebase_admin import messaging

    if get_firebase_app() is None or not topic:
        return None
    message = messaging.Message(
        topic=topic,
        notification=messaging.Notification(title=title, body=body),
        data={str(k): str(v) for k, v in (data or {}).items()},
        android=messaging.AndroidConfig(priority="high"),
    )
    try:
        return messaging.send(message, app=_require_app())
    except Exception as exc:  # noqa: BLE001
        logger.warning("FCM send_to_topic failed: %s", exc)
        return None


def send_to_tokens(tokens, title: str, body: str = "", data: dict | None = None):
    from firebase_admin import messaging

    if get_firebase_app() is None or not tokens:
        return None
    message = messaging.MulticastMessage(
        tokens=[t for t in tokens if t],
        notification=messaging.Notification(title=title, body=body),
        data={str(k): str(v) for k, v in (data or {}).items()},
        android=messaging.AndroidConfig(priority="high"),
    )
    try:
        return messaging.send_multicast(message, app=_require_app()).success_count
    except Exception as exc:  # noqa: BLE001
        logger.warning("FCM send_to_tokens failed: %s", exc)
        return None
