import django, os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from api.models import Post
posts = Post.objects.all().order_by('-createdAt')[:20]
for p in posts:
    print(f'ID: {p.id}, imageUrl repr: {repr(p.imageUrl)}, caption: {p.caption}')