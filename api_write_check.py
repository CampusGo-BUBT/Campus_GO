import requests

base = "http://127.0.0.1:8000"
results = []


def t(name, resp, expect=None):
    ok = resp.status_code in (200, 201, 204) if expect is None else resp.status_code == expect
    extra = ""
    try:
        b = resp.json()
        if isinstance(b, list):
            extra = f"[{len(b)} items]"
        elif isinstance(b, dict):
            extra = str(b)[:100]
    except Exception:
        extra = resp.text[:80]
    results.append((name, resp.status_code, ok))
    print(("PASS" if ok else "FAIL"), name, resp.status_code, extra)


r = requests.post(base + "/api/auth/login/", json={"email": "ragibraiyan01@gmail.com", "password": "password"})
tok = r.json()["access"]
uid = r.json()["user"]["id"]
h = {"Authorization": "Bearer " + tok}

# create post
r = requests.post(base + "/api/posts/", json={"caption": "Test post from api check", "type": "general"}, headers=h)
t("create post", r, 201)
post_id = r.json().get("id") if r.status_code == 201 else None

# like / save
if post_id:
    t("like post", requests.post(base + f"/api/posts/{post_id}/like/", json={"currentlyLiked": False}, headers=h))
    t("save post", requests.post(base + f"/api/posts/{post_id}/save/", json={"currentlySaved": False}, headers=h))
    t("saved list", requests.get(base + "/api/posts/saved/", headers=h))

# create book
r = requests.post(base + "/api/books/", json={"title": "Test Book", "author": "Test Author", "price": 100, "condition": "Good"}, headers=h)
t("create book", r, 201)

# create job
r = requests.post(base + "/api/jobs/", json={"title": "Test Job", "company": "Test Co", "location": "Dhaka", "salary": "10k"}, headers=h)
t("create job", r, 201)

# create hostel
r = requests.post(base + "/api/hostels/", json={"name": "Test Hostel", "location": "BUBT", "rent": 3000, "gender": "Boys"}, headers=h)
t("create hostel", r, 201)

# create notice
r = requests.post(base + "/api/notices/", json={"title": "Test Notice", "content": "Testing", "category": "Important"}, headers=h)
t("create notice", r, 201)

# create tutor
r = requests.post(base + "/api/tutors/", json={"title": "Test Tutor", "subject": "Math", "location": "Dhaka", "salary": "5k"}, headers=h)
t("create tutor", r, 201)
tutor_id = r.json().get("id") if r.status_code == 201 else None

# apply for tuition
if tutor_id:
    t("apply tuition", requests.post(base + f"/api/tutors/{tutor_id}/apply/", json={"phone": "017", "note": "interested"}, headers=h), 201)

# create study group
r = requests.post(base + "/api/study-groups/", json={"name": "Test Group", "subject": "Test Subject"}, headers=h)
t("create study group", r, 201)
group_id = r.json().get("id") if r.status_code == 201 else None

# group message
if group_id:
    t("send group msg", requests.post(base + f"/api/study-groups/{group_id}/messages/", json={"message": "Hello group"}, headers=h), 201)
    t("get group msgs", requests.get(base + f"/api/study-groups/{group_id}/messages/", headers=h))

# update profile
t("update profile", requests.patch(base + "/api/auth/user/profile/", json={"phone": "01711111111"}, headers=h))

# notifications read_all
t("notifications read_all", requests.post(base + "/api/notifications/read_all/", headers=h))

print("---")
print("TOTAL", sum(1 for r in results if r[2]), "passed /", len(results), "total")
print("FAILED:", [r[0] for r in results if not r[2]])
