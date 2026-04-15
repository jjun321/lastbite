from django.urls import path

from notification.views import NotificationLogView, NotificationReadAllView, NotificationSettingsView

urlpatterns = [
    path("", NotificationLogView.as_view(), name="notification-log-list"),
    path("read/", NotificationReadAllView.as_view(), name="notification-read-all"),
    path("settings/", NotificationSettingsView.as_view(), name="notification-settings"),
]
