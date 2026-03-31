from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("store.urls")),
    path("", include("product.urls")),
    path("orders/", include("order.urls")),
    path("cart/", include("cart.urls")),
]
