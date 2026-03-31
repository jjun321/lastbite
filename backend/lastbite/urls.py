from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("stores/", include("store.urls")),
    path("stores/", include("product.urls")),
    path("orders/", include("order.urls")),
    path("cart/", include("cart.urls")),
]
