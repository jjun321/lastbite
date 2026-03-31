from django.urls import path

from order.views import OrderCancelView, OrderDetailView, OrderView

urlpatterns = [
    path('', OrderView.as_view(), name='order-list-create'),
    path('<int:order_id>/', OrderDetailView.as_view(), name='order-detail'),
    path('<int:order_id>/cancel/', OrderCancelView.as_view(), name='order-cancel'),
]
