from django.urls import path
from .views import StoreListView, StoreDetailView, StoreHoursView

urlpatterns = [
    path('', StoreListView.as_view(), name='store-list'),
    path('<int:store_id>/', StoreDetailView.as_view(), name='store-detail'),
    path('<int:store_id>/hours/', StoreHoursView.as_view(), name='store-hours'),
]