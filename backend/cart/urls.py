from django.urls import path

from cart.views import CartItemDetailView, CartItemView, CartView

urlpatterns = [
    path('', CartView.as_view(), name='cart'),
    path('items/', CartItemView.as_view(), name='cart-item-add'),
    path('items/<str:cart_item_id>/', CartItemDetailView.as_view(), name='cart-item-detail'),
]
