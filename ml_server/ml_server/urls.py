from django.urls import path, include

urlpatterns = [
    path("", include("recommend.urls")),
    path("anomaly/", include("anomaly.urls")),
]
