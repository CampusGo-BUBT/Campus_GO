# CampusGo Backend (Django)

REST API **gateway** for the CampusGo Flutter app. The frontend no longer talks
to Firebase directly: every request goes to this API, which authenticates it and
then reads/writes **Firebase (Firestore, Storage, FCM)** using the Admin SDK.
Firebase stays the source of truth, so the app's real-time Firestore listeners
keep working.

```
Flutter app ──HTTP──▶ Django API ──Admin SDK──▶ Firebase (Firestore/Storage/FCM)
   (Firebase Auth)        │
                          └── verifies Firebase ID token, enforces business rules
```

## Features

- **Auth** – register (creates the Firebase Auth account + Firestore `users/{uid}`
  profile) and login (Firebase Identity Toolkit → returns a Firebase ID token).
  The ID token is sent as `Authorization: Bearer <idToken>` on every request.
- **Posts** – feed CRUD, like / unlike, save / unsave, saved-posts feed
- **Books** – CRUD, filter by `condition`
- **Jobs** – CRUD, search, FCM broadcast on new post
- **Hostels** – CRUD, filter by `gender` / `type`
- **Notices** – CRUD, filter by `category`, FCM broadcast on new notice
- **Tutors** – CRUD, apply to a tuition job, search, FCM broadcast on new post
- **Study groups** – CRUD, join / leave, group chat (messages subcollection)
- **Direct chat** – 1-to-1 conversations, send messages, conversation inbox
- **Notifications** – in-app notifications + **FCM push** (Firestore
  `notifications` collection + the app's `all_updates` topic)
- **Image / attachment upload** – multipart uploads are forwarded to **Firebase
  Storage** and the download URL is stored in the document

## Architecture (MVC + layered)

```
backend/
├── manage.py
├── requirements.txt
├── .env.example
├── config/                  # Django project (settings, urls, wsgi, asgi)
└── api/
    ├── authentication.py    # Firebase ID-token verification (DRF auth)
    ├── models/              # user.py only - Django identity mapping for /admin
    ├── dtos/                # DTO layer - validate input + shape output
    │   └── auth_dto.py post_dto.py book_dto.py ... (one per domain)
    ├── repositories/        # Repository layer - all Firestore data access
    │   └── user_repository.py post_repository.py ... (one per domain)
    ├── services/            # Service layer - business logic (+ Firebase/FCM)
    │   └── auth_service.py post_service.py ... firebase_service.py
    ├── controllers/         # Controller layer - thin HTTP views
    │   └── auth_controller.py post_controller.py ... (one per domain)
    ├── urls.py              # routes -> controllers
    ├── admin.py
    └── management/commands/seed.py
```

Request flow:

```
URL → Controller (parse HTTP / pick DTOs) → Service (business rules)
      → Repository (Firestore via Admin SDK) → DTO (serialize response) → JSON
```

| Layer | Responsibility | Lives in |
| ----- | -------------- | -------- |
| **Model** | `User` identity mapping for Django admin (business data lives in Firestore) | `api/models/` |
| **DTO** | Validate input, shape output (field names = Firestore keys) | `api/dtos/` |
| **Repository** | Every Firestore read / write | `api/repositories/` |
| **Service** | Business rules (ownership, apply, join, FCM broadcast…) | `api/services/` |
| **Controller** | HTTP request/response, wiring DTOs → services | `api/controllers/` |

## Firebase integration

The app uses Firebase project **`campusgo-86968`** (sender id `186247273220`).
`api/services/firebase_service.py` centralises everything:

- **Auth** – `verify_id_token` (used by `api/authentication.py`),
  `create_firebase_user` (register), `sign_in_with_password` (login via the
  Firebase Identity Toolkit REST API).
- **Firestore** – `get_collection()` returns the Admin SDK client; every
  repository maps 1:1 to a collection the app already uses
  (`users, posts, books, jobs, hostels, notices, tutors, tuition_applications,
  study_groups, conversations, notifications` + messages subcollections).
- **Storage** – `upload_file()` puts multipart uploads in the project bucket and
  returns a public URL.
- **FCM** – `send_to_token` / `send_to_topic` / `send_to_tokens`. New
  jobs / notices / tuition posts broadcast to the app's `all_updates` topic.
- **FCM tokens** – `PATCH /api/auth/user/token/` stores the device token on the
  Firestore `users` doc.

### Required configuration

1. **Service account key** – Firebase Console → Project settings → Service
   accounts → *Generate new private key*, then set one of:

   ```
   GOOGLE_APPLICATION_CREDENTIALS=C:\secrets\campusgo-firebase-adminsdk.json
   # or FIREBASE_CREDENTIALS_PATH / FIREBASE_SERVICE_ACCOUNT_JSON / FIREBASE_SERVICE_ACCOUNT_B64
   ```

2. **Web API key** – Firebase Console → Project settings → General → Web API Key:

   ```
   FIREBASE_WEB_API_KEY=AIzaSyAXQN3jPOaNlydGwYChJDEO0gTmuVDC4tE
   ```

Without credentials the API still runs: unauthenticated requests get `401` and
data operations return a clear `400` explaining what to configure.

> **Easiest setup**: drop the downloaded service-account JSON into `backend/`
> (e.g. `service-account.json` or any `*-adminsdk*.json`) — it is auto-discovered
> on startup. Verify with `python manage.py check_firebase`.

> Firestore composite indexes: `where(savedBy, array_contains, ...)`, inbox
> (`participants` array_contains) and `where(userId, ...)` + ordering may need a
> composite index. The admin SDK errors include the console link to create it;
> several repositories already sort in memory to avoid this.

## Requirements

- Python 3.10+
- pip

## Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS / Linux

pip install -r requirements.txt
cp .env.example .env           # edit if needed (development defaults are fine)

python manage.py makemigrations api
python manage.py migrate
python manage.py createsuperuser   # optional, for /admin
python manage.py seed               # optional, demo data

python manage.py runserver          # http://127.0.0.1:8000/
```

## API overview

| Method | Endpoint | Notes |
| ------ | -------- | ----- |
| GET | `/api/health/` | liveness + Firebase/Firestore connectivity probe (no auth) |
| POST | `/api/auth/register/` | body: name, email, password, userType, studentId (11 digits for students), university, phone → creates Firebase Auth account + profile |
| POST | `/api/auth/login/` | body: email + password → `{ access, refresh, user }` (`access` is a Firebase ID token) |
| GET | `/api/auth/user/` | current user profile (`userType`, etc.) |
| PATCH | `/api/auth/user/` | update profile: name, university, studentId, phone |
| PATCH | `/api/auth/user/profile/` | same as above; also accepts multipart `photo` file (avatar → Storage) |
| PATCH | `/api/auth/user/token/` | body: `fcmToken` |
| GET | `/api/users/{uid}/` | another user's public profile |
| GET/POST | `/api/posts/` | `?authorId=` filter; multipart `image` optional |
| GET | `/api/posts/saved/` | saved posts for current user |
| POST | `/api/posts/{id}/like/` | body: `currentlyLiked` bool |
| POST | `/api/posts/{id}/save/` | body: `currentlySaved` bool |
| GET/POST | `/api/books/` | `?condition=` filter; multipart `image` optional |
| DELETE | `/api/books/{id}/` | owner only |
| GET/POST | `/api/jobs/` | `?search=` |
| DELETE | `/api/jobs/{id}/` | owner only |
| GET/POST | `/api/hostels/` | `?gender=Boys|Girls`; multipart `image` optional |
| DELETE | `/api/hostels/{id}/` | owner only |
| GET/POST | `/api/notices/` | `?category=`; multipart `attachment` optional |
| DELETE | `/api/notices/{id}/` | owner only |
| GET/POST | `/api/tutors/` | `?search=` |
| POST | `/api/tutors/{id}/apply/` | body: `note`, `phone` |
| GET | `/api/tuition-applications/` | current user's applications |
| GET/POST | `/api/study-groups/` | `?search=` |
| POST | `/api/study-groups/{id}/join/` | join a group |
| POST | `/api/study-groups/{id}/leave/` | leave a group |
| GET/POST | `/api/study-groups/{id}/messages/` | group chat |
| GET | `/api/conversations/` | inbox for current user |
| POST | `/api/conversations/send/` | body: `otherUserId`, `message` |
| GET/POST | `/api/conversations/{id}/messages/` | 1-to-1 chat |
| GET | `/api/notifications/` | current user's in-app notifications |
| POST | `/api/notifications/{id}/read/` | mark one notification read |
| POST | `/api/notifications/read_all/` | mark all read |
| GET | `/api/notifications/unread_count/` | unread count badge |

### Auth header

Every request except `register` and `login` requires a **Firebase ID token**
(the one the app gets from Firebase Auth, or from `/api/auth/login/`):

```
Authorization: Bearer <firebase_id_token>
```

### Connect the Flutter app

The app keeps Firebase Auth for getting its ID token, and its Firestore
listeners / models still work (data stays in Firestore). What changes: all
*reads and writes* go through this API instead of the Firestore SDK.

- Point requests at `http://127.0.0.1:8000/api/...` (or `http://10.0.2.2:8000`
  from an Android emulator).
- Attach the user's current Firebase ID token:
  `FirebaseAuth.instance.currentUser!.getIdToken()` → `Authorization: Bearer <token>`.
- Response field names match the Firestore keys (e.g. `userId`, `sellerName`,
  `postedAt`), so the existing `fromMap` models keep parsing.
- Optional multipart `image` / `attachment` fields forward files to Firebase
  Storage through the backend.
