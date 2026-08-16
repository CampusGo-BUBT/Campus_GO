"""Tutor DTOs - Firestore `tutors` and `tuition_applications` documents.

tutors keys: jobId, title, tutoringType, location, subLocation, medium,
studentClass, preferredTutor, subject, daysPerWeek, salary, hourlyRate,
requirements, phone, userId, posterName, postedAt, applicants[].

tuition_applications keys: tuitionId, applicantId, applicantName, applicantPhone,
note, status, appliedAt.
"""
from rest_framework import serializers


class TutorJobDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    jobId = serializers.CharField(read_only=True, default="")
    title = serializers.CharField(required=True, max_length=200)
    tutoringType = serializers.ChoiceField(
        choices=["Home Tutoring", "Online", "Coaching"], default="Home Tutoring"
    )
    location = serializers.CharField(required=False, allow_blank=True, max_length=200)
    subLocation = serializers.CharField(required=False, allow_blank=True, max_length=200)
    medium = serializers.CharField(required=False, allow_blank=True, max_length=100)
    studentClass = serializers.CharField(required=False, allow_blank=True, max_length=100)
    preferredTutor = serializers.CharField(required=False, allow_blank=True, max_length=100)
    subject = serializers.CharField(required=False, allow_blank=True, max_length=150)
    daysPerWeek = serializers.CharField(required=False, allow_blank=True, max_length=50)
    salary = serializers.CharField(required=False, allow_blank=True, max_length=120)
    hourlyRate = serializers.FloatField(min_value=0, required=False, default=6000)
    requirements = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    userId = serializers.CharField(read_only=True, default="")
    posterName = serializers.CharField(read_only=True, default="")
    postedAt = serializers.DateTimeField(read_only=True, allow_null=True)
    applicants = serializers.ListField(
        child=serializers.CharField(), read_only=True, default=list
    )


class TuitionApplicationDto(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    tuitionId = serializers.CharField(read_only=True, default="")
    applicantId = serializers.CharField(read_only=True, default="")
    applicantName = serializers.CharField(read_only=True, default="")
    applicantPhone = serializers.CharField(read_only=True, default="")
    note = serializers.CharField(read_only=True, default="")
    status = serializers.CharField(read_only=True, default="pending")
    appliedAt = serializers.DateTimeField(read_only=True, allow_null=True)
