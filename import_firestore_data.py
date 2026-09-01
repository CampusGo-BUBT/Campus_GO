"""Import the real Firestore data (manually exported) into MongoDB.

One-way, idempotent import of the Firebase collections the client dumped.
Runs standalone:  python import_firestore_data.py

Timestamps are the client's local time (UTC+6), preserved as-is.
"""
import os
from datetime import datetime, timedelta, timezone

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from api.services import mongo_service  # noqa: E402

TZ = timezone(timedelta(hours=6))


def dt(y, mo, d, h=0, mi=0, s=0):
    return datetime(y, mo, d, h, mi, s, tzinfo=TZ)


db = mongo_service.get_db()


def upsert(coll, doc_id, data):
    payload = dict(data)
    payload["_id"] = str(doc_id)
    db[coll].replace_one({"_id": str(doc_id)}, payload, upsert=True)


# ── users (doc id == firebase uid) ──────────────────────────────────────────
users = [
    ("1456W24sTJYBqn4ADiFWnuopERH2", {
        "name": "asdasd", "email": "kaalka@gmail.com", "userType": "student",
        "studentId": "12123132132", "university": "BUBT", "department": "",
        "phone": "", "photoUrl": "", "fcmToken": "eEpI68Tf3hadMqOU8-B30d:APA91bGhNFV9hfaxbnhww3CG6BswiIqeCjUkFGon_MQkjgLDgvuPFXohRxXlpMc3Z2ICfQuFtnusLZnAWZzRTuGMkzj_eJ3iTIu1fTnPm76tecShd1Xv2qI",
        "createdAt": dt(2026, 7, 17, 2, 46, 39),
    }),
    ("nJUvqk8yiWRCIzju3vBuC20f3bZ2", {
        "name": "Arman Ahmed Taief", "email": "", "userType": "student",
        "studentId": "", "university": "", "department": "",
        "phone": "+8801732520196", "photoUrl": "", "fcmToken": "",
        "createdAt": dt(2026, 7, 20, 0, 0, 0),
    }),
    ("QMbjQLeD3ENNvbM2CmfrCBgSW9k1", {
        "name": "Arafat Hossain", "email": "student@campusgo.app", "userType": "student",
        "studentId": "12345678901", "university": "BUBT", "department": "",
        "phone": "01700000000", "photoUrl": "", "fcmToken": "",
        "createdAt": dt(2026, 7, 18, 0, 0, 0),
    }),
    ("LMfLATzulBO9XSvlHyGLxf162tq2", {
        "name": "E2E User B", "email": "e2e_b@campusgo.app", "userType": "student",
        "studentId": "", "university": "", "department": "", "phone": "01700000001",
        "photoUrl": "", "fcmToken": "", "createdAt": dt(2026, 8, 16, 19, 57, 44),
    }),
    ("22i9r1813kN76WpURsxbvmlCSbF3", {
        "name": "E2E User C", "email": "e2e_c@campusgo.app", "userType": "student",
        "studentId": "", "university": "", "department": "", "phone": "",
        "photoUrl": "", "fcmToken": "", "createdAt": dt(2026, 8, 16, 19, 57, 44),
    }),
    ("jKSAKCjrnCNIKPK8JwlH3qA4f3A2", {
        "name": "E2E User B", "email": "e2e_b2@campusgo.app", "userType": "student",
        "studentId": "", "university": "", "department": "", "phone": "01700000001",
        "photoUrl": "", "fcmToken": "", "createdAt": dt(2026, 8, 16, 19, 56, 2),
    }),
]
for uid, data in users:
    upsert("users", uid, data)

# ── posts ───────────────────────────────────────────────────────────────────
upsert("posts", "fs_post_1", {
    "authorId": "nJUvqk8yiWRCIzju3vBuC20f3bZ2",
    "authorName": "Arman Ahmed Taief",
    "authorHandle": "@armanahmedtaief",
    "authorPhotoUrl": "",
    "caption": "hhh",
    "imageUrl": "https://picsum.photos/seed/fs_post_1/600/400",
    "type": "job",
    "likedBy": ["xr7THI7XSQZNYoSaVsGJnKzHJHL2", "gDEzeMhB07Yvq87mnri3moiKz2v1"],
    "savedBy": [],
    "commentCount": 0,
    "createdAt": dt(2026, 7, 24, 13, 21, 31),
})

# ── books ───────────────────────────────────────────────────────────────────
upsert("books", "fs_book_1", {
    "title": "hi", "author": "helo", "price": 1000, "originalPrice": 1000,
    "condition": "Good", "phone": "+8801732520196",
    "userId": "nJUvqk8yiWRCIzju3vBuC20f3bZ2", "sellerName": "Arman Ahmed Taief",
    "imageUrl": "https://picsum.photos/seed/fs_book_1/400/500",
    "description": "hello", "rating": 4.5, "reviewCount": 12,
    "createdAt": dt(2026, 8, 12, 1, 28, 27),
})

# ── hostels ─────────────────────────────────────────────────────────────────
upsert("hostels", "fs_hostel_1", {
    "name": "ghhh", "type": "Boys", "location": "vghy", "rent": 555,
    "facilities": "hh", "facilitiesList": ["Wifi", "A/C", "Study", "Laundry", "Parking"],
    "phone": "666", "userId": "nJUvqk8yiWRCIzju3vBuC20f3bZ2",
    "ownerName": "Arman Ahmed Taief", "gender": "Boys",
    "imageUrl": "https://picsum.photos/seed/fs_hostel_1/600/400",
    "images": ["https://picsum.photos/seed/fs_hostel_1a/600/400"],
    "rating": 3.7, "reviewCount": 64,
    "distance": "Jahar Town - 0.8 km from bubt", "description": "h",
    "createdAt": dt(2026, 8, 16, 0, 5, 5),
})

# ── jobs ────────────────────────────────────────────────────────────────────
upsert("jobs", "fs_job_1", {
    "title": "Social media Moderator", "company": "remote", "location": "home",
    "salary": "5000", "type": "Part Time", "workplaceType": "On-site",
    "description": "all Social media handle",
    "requirements": [
        "Proven experience as a UI/UX Designer",
        "Strong portfolio of design projects",
        "Proficiency in Figma, Adobe XD, or Sketch",
        "Good understanding of user-centered design",
    ],
    "benefits": ["Health Insurance", "Flexible Hours", "Career Growth", "Remote Options"],
    "applicantCount": 23, "contactEmail": "haque370370@gmail.com", "phone": "",
    "userId": "nJUvqk8yiWRCIzju3vBuC20f3bZ2", "posterName": "Arman Ahmed Taief",
    "createdAt": dt(2026, 8, 12, 19, 28, 36),
})

# ── notices ─────────────────────────────────────────────────────────────────
upsert("notices", "fs_notice_1", {
    "title": "Midterm Exam Routine 2026", "content": "Midterm exams start next month.",
    "category": "Exams", "dateStr": "", "attachmentName": "", "attachmentUrl": "",
    "userId": "QMbjQLeD3ENNvbM2CmfrCBgSW9k1", "authorName": "Arafat Hossain",
    "createdAt": dt(2026, 8, 17, 1, 48, 27),
})

# ── tutors ──────────────────────────────────────────────────────────────────
upsert("tutors", "fs_tutor_1", {
    "jobId": "54413237", "title": "Tutor Needed For Class 6",
    "tutoringType": "Home Tutoring", "location": "Mirpur-2, Dhaka",
    "subLocation": "Near Mirpur National Stadium", "medium": "English Version",
    "studentClass": "Class 6", "preferredTutor": "Male", "subject": "Science",
    "daysPerWeek": "4 Days/Week", "salary": "6,000 Tk/Month", "hourlyRate": 6000,
    "requirements": "Looking for an experienced and punctual tutor who has great knowledge of mathematics, science and English grammar. Daily 2 hours lesson requested.",
    "phone": "9494", "userId": "nJUvqk8yiWRCIzju3vBuC20f3bZ2",
    "posterName": "Arman Ahmed Taief", "postedAt": dt(2026, 8, 15, 23, 36, 37),
    "applicants": [], "sourcePostId": None,
})

# ── tuition_applications ────────────────────────────────────────────────────
upsert("tuition_applications", "fs_ta_1", {
    "tuitionId": "2MoJM48Z1HX1lnfrkHKL",
    "applicantId": "jKSAKCjrnCNIKPK8JwlH3qA4f3A2",
    "applicantName": "E2E User B", "applicantPhone": "01700000001",
    "note": "I can teach", "status": "pending",
    "appliedAt": dt(2026, 8, 17, 1, 56, 10),
})

# ── study_groups ────────────────────────────────────────────────────────────
upsert("study_groups", "fs_group_1", {
    "name": "New group", "subject": "all", "description": "aa", "location": "d",
    "time": "ads", "maxMembers": 5,
    "members": [
        "1456W24sTJYBqn4ADiFWnuopERH2",
        "nJUvqk8yiWRCIzju3vBuC20f3bZ2",
        "5T4mcZhd4la2aUZTC3BU6ffAUui1",
        "5YQ06LA9TyUljTB97Ii82XTZhWQ2",
    ],
    "creatorId": "1456W24sTJYBqn4ADiFWnuopERH2", "creatorName": "asdasd",
    "messages": [],
})

# ── conversations (doc id == sorted participant pair) ────────────────────────
conv_id = "_".join(sorted(["LMfLATzulBO9XSvlHyGLxf162tq2", "22i9r1813kN76WpURsxbvmlCSbF3"]))
upsert("conversations", conv_id, {
    "participants": ["LMfLATzulBO9XSvlHyGLxf162tq2", "22i9r1813kN76WpURsxbvmlCSbF3"],
    "lastMessage": "hi from B", "lastMessageTime": dt(2026, 8, 17, 1, 57, 56),
    "lastSenderId": "LMfLATzulBO9XSvlHyGLxf162tq2",
    "createdAt": dt(2026, 8, 17, 1, 57, 55),
    "messages": [],
})

print("Firestore data imported.")
for c in ["users", "posts", "books", "hostels", "jobs", "notices", "tutors",
          "tuition_applications", "study_groups", "conversations"]:
    print(f"  {c}: {db[c].count_documents({})}")
