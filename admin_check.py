import requests

base = "http://127.0.0.1:8000"


def t(name, resp, expect=None):
    ok = resp.status_code in (200, 201, 204) if expect is None else resp.status_code == expect
    print(("PASS" if ok else "FAIL"), name, resp.status_code, str(resp.json())[:120])


# admin login (password "1")
r = requests.post(base + "/api/auth/login/", json={"email": "admin@gmail.com", "password": "1"})
t("admin login (password 1)", r)
admin_tok = r.json()["access"]
admin_uid = r.json()["user"]["id"]
print("  admin userType:", r.json()["user"].get("userType"))
h = {"Authorization": "Bearer " + admin_tok}

# dashboard
t("admin dashboard", requests.get(base + "/api/admin/dashboard/", headers=h))
# pending items
t("admin pending items", requests.get(base + "/api/admin/items/", headers=h))
# users list
t("admin users list", requests.get(base + "/api/admin/users/", headers=h))

# normal user login
r = requests.post(base + "/api/auth/login/", json={"email": "ragibraiyan01@gmail.com", "password": "password"})
user_tok = r.json()["access"]
uh = {"Authorization": "Bearer " + user_tok}
# normal user cannot access admin
t("normal user -> dashboard (403 expected)", requests.get(base + "/api/admin/dashboard/", headers=uh), 403)

# test create a job (should be pending, not visible)
r = requests.post(base + "/api/jobs/", json={"title": "Test Job", "company": "X", "location": "Y", "salary": "100"}, headers=uh)
t("create job", r, 201)
job_id = r.json()["id"]
print("  job status:", r.json().get("status"))
# public jobs should not include it
jobs = requests.get(base + "/api/jobs/", headers=uh).json()
print("  public jobs count:", len(jobs), "(new job hidden)")
# admin pending should include it
pend = requests.get(base + "/api/admin/items/", headers=h).json()
print("  pending items count:", len(pend))
# approve it
t("approve job", requests.post(base + f"/api/admin/moderate/job/{job_id}/approve/", headers=h))
# now public jobs include it
jobs = requests.get(base + "/api/jobs/", headers=uh).json()
print("  public jobs after approve:", len(jobs))
