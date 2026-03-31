from django.urls import path
from .views import LoginView, RegisterView, RefreshTokenView, LogoutView, EmailCheckView, PasswordResetRequestView, PasswordResetConfirmCheckView, PasswordResetConfirmView

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