import django
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from api.services import mongo_service

db = mongo_service.get_db()
db.posts.delete_many({"caption": {"$regex": "^Test|^file upload|^url test"}})
db.books.delete_many({"title": "Test Book"})
db.jobs.delete_many({"title": "Test Job"})
db.hostels.delete_many({"name": "Test Hostel"})
db.notices.delete_many({"title": "Test Notice"})
db.tutors.delete_many({"title": "Test Tutor"})
db.study_groups.delete_many({"name": "Test Group"})
print("cleanup done")
print("posts:", db.posts.count_documents({}))
print("books:", db.books.count_documents({}))
print("jobs:", db.jobs.count_documents({}))
print("hostels:", db.hostels.count_documents({}))
