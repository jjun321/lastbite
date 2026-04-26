from django.urls import path
from .views import StoreProductListView, CategoryListView, CategoryDetailView

urlpatterns = [
    path('<int:store_id>/products/', StoreProductListView.as_view(), name='store-products'),
]

categories_urlpatterns = [
    path('', CategoryListView.as_view(), name='store-categories/'),
    path('<int:category_id>/', CategoryDetailView.as_view(), name='store-categories-detail/'),
]