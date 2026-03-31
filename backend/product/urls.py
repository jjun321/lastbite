from django.urls import path
from .views import StoreProductListView

urlpatterns = [
    path('<int:store_id>/products/', StoreProductListView.as_view(), name='store-products'),
]