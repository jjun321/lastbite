from django.urls import path
from product.anomaly_views import AnomalyCheckView, AnomalyNotifySpecialDealsView

urlpatterns = [
    path("check/",                AnomalyCheckView.as_view(),               name="anomaly-check"),
    path("notify-special-deals/", AnomalyNotifySpecialDealsView.as_view(),  name="anomaly-notify"),
]
