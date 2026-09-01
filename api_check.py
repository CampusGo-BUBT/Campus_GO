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
        elif isinstance(b, dict) and "detail" in b:
            extra = "detail=" + str(b["detail"])[:60]
    except Exception:
        pass
    results.append((name, resp.status_code, ok))
    print(("PASS" if ok else "FAIL"), name, resp.status_code, extra)


r = requests.post(
    base + "/api/auth/login/",
    json={"email": "ragibraiyan01@gmail.com", "password": "password"},
)
t("login", r)
tok = r.json()["access"]
uid = r.json()["user"]["id"]
h = {"Authorization": "Bearer " + tok}

t("health", requests.get(base + "/api/health/"))
t("me", requests.get(base + "/api/auth/user/", headers=h))
t("users/{uid}", requests.get(base + f"/api/users/{uid}/", headers=h))
t("posts list", requests.get(base + "/api/posts/", headers=h))
t("posts type=book", requests.get(base + "/api/posts/", params={"type": "book"}, headers=h))
t("posts type=job", requests.get(base + "/api/posts/", params={"type": "job"}, headers=h))
t("posts type=hostel", requests.get(base + "/api/posts/", params={"type": "hostel"}, headers=h))
t("posts type=study", requests.get(base + "/api/posts/", params={"type": "study"}, headers=h))
t("posts saved", requests.get(base + "/api/posts/saved/", headers=h))
t("books list", requests.get(base + "/api/books/", headers=h))
t("jobs list", requests.get(base + "/api/jobs/", headers=h))
t("hostels list", requests.get(base + "/api/hostels/", headers=h))
t("notices list", requests.get(base + "/api/notices/", headers=h))
t("tutors list", requests.get(base + "/api/tutors/", headers=h))
t("tuition-applications", requests.get(base + "/api/tuition-applications/", headers=h))
t("study-groups list", requests.get(base + "/api/study-groups/", headers=h))
t("conversations list", requests.get(base + "/api/conversations/", headers=h))
t("notifications list", requests.get(base + "/api/notifications/", headers=h))
t("notifications unread", requests.get(base + "/api/notifications/unread_count/", headers=h))

print("---")
print("TOTAL", sum(1 for r in results if r[2]), "passed /", len(results), "total")
print("FAILED:", [r[0] for r in results if not r[2]])
