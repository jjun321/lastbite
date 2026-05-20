from django.urls import path
from .views import StoreProductListView, CategoryListView, CategoryDetailView, ProductSearchView, HotDealView

urlpatterns = [
    path('<int:store_id>/products/', StoreProductListView.as_view(), name='store-products'),
]

product_urlpatterns = [
    path('search/',  ProductSearchView.as_view(), name='product-search'),
    path('hotdeal/', HotDealView.as_view(),       name='product-hotdeal'),
]

categories_urlpatterns = [
    path('', CategoryListView.as_view(), name='store-categories/'),
    path('<int:category_id>/', CategoryDetailView.as_view(), name='store-categories-detail/'),
]