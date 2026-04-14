

from django.urls import path
from .owner_views import (
    OwnerStoreView,
    OwnerStoreMeView,
    OwnerStoreManageView,
    OwnerOffDateView,
    OwnerOffDateDeleteView,
    OwnerWorkingTimeView,
    OwnerWorkingTimeManageView,
)


# /owner/stores/로 접근, 프리픽스 루트 url애서 지정
# 기능 특성상 아예 접근 원천적으로 분리하기 위해 url 새로 라우팅

urlpatterns = [
    path('', OwnerStoreView.as_view(), name='owner-store-create'),
    path('me/', OwnerStoreMeView.as_view(), name='owner-store-me'),
    path('<int:store_id>/', OwnerStoreManageView.as_view(), name='owner-store-manage'),
    path('<int:store_id>/off-dates/', OwnerOffDateView.as_view(), name='owner-off-date'),
    path('<int:store_id>/off-dates/<int:date_id>/', OwnerOffDateDeleteView.as_view(), name='owner-off-date-delete'),
    path('<int:store_id>/working-times/', OwnerWorkingTimeView.as_view(), name='owner-working-time'),
    path('<int:store_id>/working-times/<int:working_time_id>/', OwnerWorkingTimeManageView.as_view(), name='owner-working-time-manage'),
]
