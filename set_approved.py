import django
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from api.services import mongo_service

db = mongo_service.get_db()
for coll in ["posts", "jobs", "hostels", "tutors"]:
    db[coll].update_many(
        {"status": {"$exists": False}}, {"$set": {"status": "approved"}}
    )
    db[coll].update_many({"status": "pending"}, {"$set": {"status": "approved"}})
    print(f"{coll}: approved count = {db[coll].count_documents({'status': 'approved'})}")
print("Existing content marked approved.")
