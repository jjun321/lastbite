from django.urls import path
from .views import LoginView, RegisterView, RefreshTokenView, LogoutView, EmailCheckView

urlpatterns = [
    path('login', LoginView.as_view(), name='login'),
    path('register', RegisterView.as_view(), name='register'),
    path('refresh', RefreshTokenView.as_view(), name='token_refresh'),
    path('logout', LogoutView.as_view(), name='logout'),
    path('check', EmailCheckView.as_view(), name='email_check'),
]