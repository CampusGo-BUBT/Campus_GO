"""Profile controller - list the current user's own content for edit/delete."""
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from api.dtos.auth_dto import UserDto
from api.dtos.book_dto import BookDto
from api.dtos.hostel_dto import HostelDto
from api.dtos.job_dto import JobDto
from api.dtos.notice_dto import NoticeDto
from api.dtos.post_dto import PostDto
from api.dtos.study_group_dto import StudyGroupDto
from api.dtos.tutor_dto import TutorJobDto
from api.repositories.book_repository import BookRepository
from api.repositories.hostel_repository import HostelRepository
from api.repositories.job_repository import JobRepository
from api.repositories.notice_repository import NoticeRepository
from api.repositories.post_repository import PostRepository
from api.repositories.study_group_repository import StudyGroupRepository
from api.repositories.tutor_repository import TutorRepository
from api.services.admin_service import admin_service

_post = PostRepository()
_book = BookRepository()
_job = JobRepository()
_hostel = HostelRepository()
_notice = NoticeRepository()
_tutor = TutorRepository()
_group = StudyGroupRepository()


class MyListingsController(APIView):
    """GET /api/profile/me/listings/
    Returns everything the current user owns, grouped by kind, so the app can
    offer edit/delete for each item.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        uid = request.user.firebase_uid
        is_admin = admin_service.is_admin(uid)

        posts = PostDto(_post.by_owner(uid, owner_key="authorId"), many=True).data
        books = BookDto(_book.by_owner(uid), many=True).data
        jobs = JobDto(_job.by_owner(uid), many=True).data
        hostels = HostelDto(_hostel.by_owner(uid), many=True).data
        notices = NoticeDto(_notice.by_owner(uid), many=True).data
        tutors = TutorJobDto(_tutor.by_owner(uid), many=True).data
        groups = StudyGroupDto(_group.by_owner(uid, owner_key="creatorId"), many=True).data

        return Response(
            {
                "isAdmin": is_admin,
                "posts": posts,
                "books": books,
                "jobs": jobs,
                "hostels": hostels,
                "notices": notices,
                "tutors": tutors,
                "studyGroups": groups,
            }
        )


class UpdateProfileFieldsController(APIView):
    """PATCH /api/profile/me/ - update name / university / studentId / phone."""

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        from api.services.auth_service import auth_service

        user = auth_service.update_profile(
            request.user.firebase_uid,
            {
                "name": request.data.get("name"),
                "university": request.data.get("university"),
                "studentId": request.data.get("studentId"),
                "phone": request.data.get("phone"),
            },
        )
        return Response(UserDto(user).data)
