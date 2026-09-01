from django.urls import include, path
from rest_framework.routers import DefaultRouter

from api.controllers.auth_controller import (
    GoogleLoginController,
    LoginController,
    MeController,
    RegisterController,
    UpdateProfileController,
    UpdateTokenController,
)
from api.controllers.admin_controller import (
    AdminDashboardController,
    AdminItemsController,
    AdminModerateController,
    AdminUsersController,
)
from api.controllers.book_controller import BookController
from api.controllers.conversation_controller import ConversationController
from api.controllers.health_controller import HealthController
from api.controllers.hostel_controller import HostelController
from api.controllers.job_controller import JobController
from api.controllers.notice_controller import NoticeController
from api.controllers.notification_controller import NotificationController
from api.controllers.post_controller import PostController
from api.controllers.study_group_controller import StudyGroupController
from api.controllers.tutor_controller import TuitionApplicationController, TutorController
from api.controllers.user_controller import UserProfileController

router = DefaultRouter()
router.register(r"posts", PostController, basename="post")
router.register(r"books", BookController, basename="book")
router.register(r"jobs", JobController, basename="job")
router.register(r"hostels", HostelController, basename="hostel")
router.register(r"notices", NoticeController, basename="notice")
router.register(r"tutors", TutorController, basename="tutor")
router.register(r"tuition-applications", TuitionApplicationController, basename="tuition-application")
router.register(r"study-groups", StudyGroupController, basename="study-group")
router.register(r"conversations", ConversationController, basename="conversation")
router.register(r"notifications", NotificationController, basename="notification")

urlpatterns = [
    path("health/", HealthController.as_view(), name="health"),
    path("auth/register/", RegisterController.as_view(), name="register"),
    path("auth/login/", LoginController.as_view(), name="login"),
    path("auth/google/", GoogleLoginController.as_view(), name="google_login"),
    path("auth/user/", MeController.as_view(), name="me"),
    path("auth/user/token/", UpdateTokenController.as_view(), name="update_fcm_token"),
    path("auth/user/profile/", UpdateProfileController.as_view(), name="update_profile"),
    path("users/<str:uid>/", UserProfileController.as_view(), name="user_profile"),
    path("admin/dashboard/", AdminDashboardController.as_view(), name="admin_dashboard"),
    path("admin/items/", AdminItemsController.as_view(), name="admin_items"),
    path(
        "admin/moderate/<str:kind>/<str:item_id>/<str:action>/",
        AdminModerateController.as_view(),
        name="admin_moderate",
    ),
    path("admin/users/", AdminUsersController.as_view(), name="admin_users"),
    path("admin/users/<str:uid>/<str:action>/", AdminUsersController.as_view(), name="admin_user_action"),
    path("", include(router.urls)),
]
