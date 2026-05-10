from django.urls import path
from anomaly.views import AnomalyDetectView, AnomalyDetectBatchView

urlpatterns = [
    path("detect/",       AnomalyDetectView.as_view(),      name="anomaly-detect"),
    path("detect-batch/", AnomalyDetectBatchView.as_view(), name="anomaly-detect-batch"),
]