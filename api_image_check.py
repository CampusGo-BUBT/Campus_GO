import io
import requests

base = "http://127.0.0.1:8000"
r = requests.post(base + "/api/auth/login/", json={"email": "ragibraiyan01@gmail.com", "password": "password"})
print("login", r.status_code)
tok = r.json()["access"]
h = {"Authorization": "Bearer " + tok}

posts = requests.get(base + "/api/posts/", headers=h).json()
with_img = [p for p in posts if p.get("imageUrl")]
print("posts total:", len(posts), "| with imageUrl:", len(with_img))
if with_img:
    print("sample imageUrl:", with_img[0]["imageUrl"])

files = {"image": ("test.png", io.BytesIO(b"\x89PNG\r\n\x1a\n" + b"0" * 100), "image/png")}
r = requests.post(base + "/api/posts/", headers=h, data={"caption": "file upload test", "type": "general"}, files=files)
print("file upload post:", r.status_code)
if r.status_code == 201:
    print("  -> imageUrl:", r.json().get("imageUrl"))

r = requests.post(base + "/api/posts/", json={"caption": "url test", "type": "general", "imageUrl": "https://picsum.photos/seed/urltest/500/400"}, headers=h)
print("url input post:", r.status_code)
if r.status_code == 201:
    print("  -> imageUrl:", r.json().get("imageUrl"))

books = requests.get(base + "/api/books/", headers=h).json()
print("books sample imageUrl:", books[0].get("imageUrl") if books else "none")
hostels = requests.get(base + "/api/hostels/", headers=h).json()
print("hostels sample imageUrl:", hostels[0].get("imageUrl") if hostels else "none")
