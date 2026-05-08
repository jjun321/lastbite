from django.urls import path
from .views import LoginView, RegisterView, RefreshTokenView, LogoutView, EmailCheckView, PasswordResetRequestView, PasswordResetConfirmCheckView, PasswordResetConfirmView, UserProfileView, PasswordChangeView, ProfileImageUploadView, UserSavingsView, UserFavoriteListView, UserLocationView, UserLocationDetailView, UserRecommendView

urlpatterns = [
    path('login', LoginView.as_view(), name='login'),
    path('register', RegisterView.as_view(), name='register'),
    path('refresh', RefreshTokenView.as_view(), name='token_refresh'),
    path('logout', LogoutView.as_view(), name='logout'),
    path('check', EmailCheckView.as_view(), name='email_check'),
    path('password/reset-request', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password/reset-confirm', PasswordResetConfirmCheckView.as_view(), name='password_reset_confirm_check'),
    path('password/reset-confirm', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
]

# 마이페이지 라우팅 분리, prefix는 루트 urls.py에서 부여하는 방식
users_urlpatterns = [
    path('me',               UserProfileView.as_view(),       name='user-profile'),
    path('me/password',      PasswordChangeView.as_view(),    name='password-change'),
    path('me/profile-image', ProfileImageUploadView.as_view(),name='profile-image-upload'),
    path('me/savings',       UserSavingsView.as_view(),       name='user-savings'),
    path('me/favorites',     UserFavoriteListView.as_view(),   name='user-favorites'),
    path('me/locations',                UserLocationView.as_view(),       name='user-locations'),
    path('me/locations/<int:log_id>',   UserLocationDetailView.as_view(), name='user-location-detail'),
    path('me/recommendations',          UserRecommendView.as_view(),      name='user-recommendations'),
]