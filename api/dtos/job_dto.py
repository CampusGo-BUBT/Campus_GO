"""Job DTO - maps a Firestore `jobs` document.

Keys: title, company, location, salary, type, workplaceType, description,
requirements[], benefits[], applicantCount, contactEmail, phone, userId,
posterName, createdAt.
"""
from rest_framework import serializers


class JobDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    title = serializers.CharField(required=True, max_length=200)
    company = serializers.CharField(required=True, max_length=200)
    location = serializers.CharField(required=True, max_length=200)
    salary = serializers.CharField(required=False, allow_blank=True, max_length=120)
    type = serializers.ChoiceField(
        choices=["Full Time", "Part Time", "Internship"], default="Full Time"
    )
    workplaceType = serializers.ChoiceField(
        choices=["On-site", "Remote", "Hybrid"], default="On-site"
    )
    description = serializers.CharField(required=False, allow_blank=True)
    requirements = serializers.ListField(
        child=serializers.CharField(), required=False, default=list
    )
    benefits = serializers.ListField(
        child=serializers.CharField(), required=False, default=list
    )
    applicantCount = serializers.IntegerField(read_only=True, default=0)
    contactEmail = serializers.EmailField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    userId = serializers.CharField(read_only=True, default="")
    posterName = serializers.CharField(read_only=True, default="")
    createdAt = serializers.DateTimeField(read_only=True, allow_null=True)
