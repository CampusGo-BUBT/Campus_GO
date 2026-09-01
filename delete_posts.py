import django, os
os.environ['DJANGO_SETTINGS_MODULE'] = 'config.settings'
django.setup()
from api.models import Post
Post.objects.all().delete()
print('Deleted all posts successfully')