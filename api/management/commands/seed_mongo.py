"""Seed MongoDB with CampusGo demo data (same field structure as Firestore).

Usage:
    python manage.py seed_mongo

Populates the `campusgo` MongoDB database with users, posts (across all
types), books, jobs, hostels, notices, tutors and study groups, so the Flutter
app shows content immediately.
"""
from datetime import datetime, timedelta

from django.core.management.base import BaseCommand

from api.services import mongo_service

UID = "EPcM281OvPM09enEJAgtSM5gTHn1"


def _ago(hours):
    return datetime.utcnow() - timedelta(hours=hours)


class Command(BaseCommand):
    help = "Seed CampusGo demo data into MongoDB."

    def handle(self, *args, **options):
        db = mongo_service.get_db()

        # ── Users ────────────────────────────────────────────────────────
        users = [
            {
                "_id": UID,
                "name": "ragib raiyan",
                "email": "ragibraiyan01@gmail.com",
                "userType": "student",
                "studentId": "20245103321",
                "university": "BUBT",
                "department": "CSE",
                "phone": "01700000000",
                "photoUrl": "",
                "fcmToken": "",
                "createdAt": _ago(48),
            },
        ]
        for u in users:
            db.users.replace_one({"_id": u["_id"]}, u, upsert=True)

        # ── Posts (type drives the section screens) ──────────────────────
        post_seeds = [
            ("book", "Data Structures and Algorithms by Karumanchi, barely used. 350 taka. DM if interested.", _ago(1)),
            ("book", "Operating System Concepts (Silberschatz) 9th edition. Price: ৳400.", _ago(5)),
            ("book", "Discrete Mathematics - Rosen. Good condition, ৳250.", _ago(12)),
            ("hostel", "Green View Boys Hostel - Jahar Town, BUBT. Rent ৳4500/month, free WiFi + generator.", _ago(2)),
            ("hostel", "Girls hostel near gate 2, single seat available. ৳3500/month.", _ago(8)),
            ("job", "UI/UX Designer needed at Creative IT Ltd. Dhaka. Salary Tk15,000-25,000.", _ago(3)),
            ("job", "Part-time Flutter Developer (remote). 2-3 hrs/day. Contact for details.", _ago(10)),
            ("study", "CSE-300 Study Squad - Software Development Project group. Library, max 8 members.", _ago(4)),
            ("study", "Math III group study tonight at BUBT library, 6pm. All welcome.", _ago(16)),
            ("tuition", "Tutor needed for Mathematics, class 8, Mirpur-2. ৳6000/month, 3 days/week.", _ago(6)),
            ("notice", "Midterm Exam Routine 2026 is published. Check the notice board.", _ago(2)),
            ("announcement", "Mid-semester results are out! Check your portal now.", _ago(7)),
            ("general", "Anyone selling a used TI calculator? Need one for the exam.", _ago(9)),
        ]
        posts = []
        for i, (ptype, caption, created) in enumerate(post_seeds):
            posts.append(
                {
                    "_id": f"seed_post_{i}",
                    "authorId": UID,
                    "authorName": "ragib raiyan",
                    "authorHandle": "@ragibraiyan",
                    "authorPhotoUrl": "",
                    "caption": caption,
                    "imageUrl": f"https://picsum.photos/seed/campusgo_post_{i}/600/400",
                    "type": ptype,
                    "likedBy": [],
                    "savedBy": [],
                    "commentCount": 0,
                    "createdAt": created,
                }
            )
        for p in posts:
            db.posts.replace_one({"_id": p["_id"]}, p, upsert=True)

        # ── Books ────────────────────────────────────────────────────────
        books = [
            {"_id": "seed_book_1", "title": "Data Structures and Algorithms", "author": "Narasimha Karumanchi", "price": 350, "originalPrice": 650, "condition": "Good", "phone": "01700000000", "userId": UID, "sellerName": "ragib raiyan", "imageUrl": "https://picsum.photos/seed/book1/400/500", "description": "Barely used, no markings.", "rating": 4.5, "reviewCount": 3, "createdAt": _ago(1)},
            {"_id": "seed_book_2", "title": "Operating System Concepts", "author": "Silberschatz", "price": 400, "originalPrice": 800, "condition": "New", "phone": "01700000000", "userId": UID, "sellerName": "ragib raiyan", "imageUrl": "https://picsum.photos/seed/book2/400/500", "description": "9th edition, brand new.", "rating": 4.8, "reviewCount": 5, "createdAt": _ago(5)},
        ]
        for b in books:
            db.books.replace_one({"_id": b["_id"]}, b, upsert=True)

        # ── Jobs ─────────────────────────────────────────────────────────
        jobs = [
            {"_id": "seed_job_1", "title": "UI/UX Designer", "company": "Creative IT Ltd.", "location": "Dhaka", "salary": "Tk15,000 - 25,000", "type": "Full Time", "workplaceType": "On-site", "description": "Design interfaces for web and mobile apps.", "requirements": ["Figma", "2+ projects"], "benefits": ["Festival bonus"], "applicantCount": 12, "contactEmail": "hr@creativeit.com", "phone": "", "userId": UID, "posterName": "ragib raiyan", "createdAt": _ago(3)},
            {"_id": "seed_job_2", "title": "Flutter Developer (Remote)", "company": "StartupHub", "location": "Remote", "salary": "Tk20,000", "type": "Part Time", "workplaceType": "Remote", "description": "Build mobile apps with Flutter.", "requirements": ["Flutter", "Dart"], "benefits": ["Flexible hours"], "applicantCount": 8, "contactEmail": "jobs@startuphub.io", "phone": "", "userId": UID, "posterName": "ragib raiyan", "createdAt": _ago(10)},
        ]
        for j in jobs:
            db.jobs.replace_one({"_id": j["_id"]}, j, upsert=True)

        # ── Hostels ──────────────────────────────────────────────────────
        hostels = [
            {"_id": "seed_hostel_1", "name": "Green View Boys Hostel", "type": "Boys", "location": "Jahar Town, BUBT", "rent": 4500, "facilities": "WiFi, Generator", "facilitiesList": ["WiFi", "Generator"], "phone": "01700000000", "userId": UID, "ownerName": "ragib raiyan", "gender": "Boys", "imageUrl": "https://picsum.photos/seed/hostel1/600/400", "images": ["https://picsum.photos/seed/hostel1a/600/400", "https://picsum.photos/seed/hostel1b/600/400"], "rating": 3.8, "reviewCount": 6, "distance": "0.5 km", "description": "Clean rooms, 3 beds per room.", "createdAt": _ago(2)},
        ]
        for h in hostels:
            db.hostels.replace_one({"_id": h["_id"]}, h, upsert=True)

        # ── Notices ──────────────────────────────────────────────────────
        notices = [
            {"_id": "seed_notice_1", "title": "Midterm Exam Routine 2026", "content": "Midterm exams start next month. Full routine is on the notice board.", "category": "Exams", "dateStr": "2026-09-01", "attachmentName": "routine.pdf", "attachmentUrl": "https://picsum.photos/seed/notice1/600/300", "userId": UID, "authorName": "ragib raiyan", "createdAt": _ago(2)},
            {"_id": "seed_notice_2", "title": "Class Cancelled - CSE 302", "content": "Today's CSE 302 lecture is postponed to Thursday.", "category": "Important", "dateStr": "", "attachmentName": "", "attachmentUrl": "", "userId": UID, "authorName": "ragib raiyan", "createdAt": _ago(6)},
        ]
        for n in notices:
            db.notices.replace_one({"_id": n["_id"]}, n, upsert=True)

        # ── Tutors ───────────────────────────────────────────────────────
        tutors = [
            {"_id": "seed_tutor_1", "jobId": "544abc1", "title": "Tutor Needed For Mathematics", "tutoringType": "Home Tutoring", "location": "Mirpur-2, Dhaka", "subLocation": "Section 6", "medium": "Bangla", "studentClass": "Class 8", "preferredTutor": "Male", "subject": "Mathematics", "daysPerWeek": "3 days", "salary": "6,000 Tk/Month", "hourlyRate": 6000, "requirements": "BSc in Math or CSE", "phone": "01700000000", "userId": UID, "posterName": "ragib raiyan", "postedAt": _ago(6), "applicants": []},
            {"_id": "seed_tutor_2", "jobId": "544def2", "title": "Physics Tutor For HSC", "tutoringType": "Online", "location": "Anywhere", "subLocation": "", "medium": "English", "studentClass": "HSC", "preferredTutor": "Any", "subject": "Physics", "daysPerWeek": "2 days", "salary": "4,000 Tk/Month", "hourlyRate": 4000, "requirements": "Good command on Physics", "phone": "01700000000", "userId": UID, "posterName": "ragib raiyan", "postedAt": _ago(20), "applicants": []},
        ]
        for t in tutors:
            db.tutors.replace_one({"_id": t["_id"]}, t, upsert=True)

        # ── Study Groups ─────────────────────────────────────────────────
        groups = [
            {"_id": "seed_group_1", "name": "CSE-300 Study Squad", "subject": "Software Development Project", "description": "Group project study + coding sessions.", "location": "Library", "time": "Evenings", "maxMembers": 8, "members": [UID], "creatorId": UID, "creatorName": "ragib raiyan", "createdAt": _ago(4), "messages": []},
            {"_id": "seed_group_2", "name": "Math III Help Group", "subject": "Mathematics III", "description": "Help each other with calculus problems.", "location": "Library 2nd floor", "time": "6pm", "maxMembers": 10, "members": [UID], "creatorId": UID, "creatorName": "ragib raiyan", "createdAt": _ago(16), "messages": []},
        ]
        for g in groups:
            db.study_groups.replace_one({"_id": g["_id"]}, g, upsert=True)

        self.stdout.write(self.style.SUCCESS("MongoDB seeded."))
        self.stdout.write(
            f"users={len(users)} posts={len(posts)} books={len(books)} jobs={len(jobs)} "
            f"hostels={len(hostels)} notices={len(notices)} tutors={len(tutors)} groups={len(groups)}"
        )
