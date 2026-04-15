from django.urls import path

from order.views import OrderCancelView, OrderDetailView, OrderView, OrderItemDetailView

urlpatterns = [
    path('', OrderView.as_view(), name='order-list-create'),
    path('<int:order_id>/', OrderDetailView.as_view(), name='order-detail'),
    path('<int:order_id>/cancel/', OrderCancelView.as_view(), name='order-cancel'),
    path('<int:order_id>/items/<int:product_id>/', OrderItemDetailView.as_view(), name='order-item-detail'),
]
