from django.urls import path
from .owner_views import (
    OwnerStoreView,
    OwnerStoreManageView,
    OwnerOffDateView,
    OwnerOffDateDeleteView,
    OwnerWorkingTimeView,
    OwnerWorkingTimeManageView,
)
from product.owner_views import (
    OwnerProductView,
    OwnerProductManageView,
    OwnerProductSoldOutView,
)
from order.owner_views import (
    OwnerOrderIncomingView,
    OwnerOrderHistoryView,
    OwnerOrderDetailView,
    OwnerOrderAcceptView,
    OwnerOrderCancelView,
    OwnerOrderCompleteView,
)

# /owner/stores/로 접근, 프리픽스 루트 url애서 지정
# 기능 특성상 아예 접근 원천적으로 분리하기 위해 url 새로 라우팅

urlpatterns = [
    path('', OwnerStoreView.as_view(), name='owner-store-create'),
    path('<int:store_id>/', OwnerStoreManageView.as_view(), name='owner-store-manage'),
    path('<int:store_id>/off-dates/', OwnerOffDateView.as_view(), name='owner-off-date'),
    path('<int:store_id>/off-dates/<int:date_id>/', OwnerOffDateDeleteView.as_view(), name='owner-off-date-delete'),
    path('<int:store_id>/working-times/', OwnerWorkingTimeView.as_view(), name='owner-working-time'),
    path('<int:store_id>/working-times/<int:working_time_id>/', OwnerWorkingTimeManageView.as_view(), name='owner-working-time-manage'),
    path('<int:store_id>/products/', OwnerProductView.as_view(), name='owner-product-list-create'),
    path('<int:store_id>/products/<int:product_id>/', OwnerProductManageView.as_view(), name='owner-product-manage'),
    path('<int:store_id>/products/<int:product_id>/soldout/', OwnerProductSoldOutView.as_view(), name='owner-product-soldout'),
    path('<int:store_id>/orders/', OwnerOrderIncomingView.as_view(), name='owner-order-incoming'),
    path('<int:store_id>/orders/history/', OwnerOrderHistoryView.as_view(), name='owner-order-history'),
    path('<int:store_id>/orders/<int:order_id>/', OwnerOrderDetailView.as_view(), name='owner-order-detail'),
    path('<int:store_id>/orders/<int:order_id>/accept/', OwnerOrderAcceptView.as_view(), name='owner-order-accept'),
    path('<int:store_id>/orders/<int:order_id>/cancel/', OwnerOrderCancelView.as_view(), name='owner-order-cancel'),
    path('<int:store_id>/orders/<int:order_id>/complete/', OwnerOrderCompleteView.as_view(), name='owner-order-complete'),
]
