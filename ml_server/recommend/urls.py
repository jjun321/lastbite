from django.urls import path
from recommend.views import RecommendView, AnomalyDetectView, AnomalyDetectBatchView

urlpatterns = [
    path("recommend/",             RecommendView.as_view(),        name="recommend"),
    path("anomaly/detect/",        AnomalyDetectView.as_view(),    name="anomaly-detect"),
    path("anomaly/detect-batch/",  AnomalyDetectBatchView.as_view(), name="anomaly-detect-batch"),
]
