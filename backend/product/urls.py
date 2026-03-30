from django.urls import path
from product.views import StoreProductListView

urlpatterns = [
    path('stores/<int:store_id>/products', StoreProductListView.as_view(), name='store-products'),
]