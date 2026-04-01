from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def home(request):
    return JsonResponse({"message": "backend test"})

urlpatterns = [
    path("", home),
    path("admin/", admin.site.urls),
    path("auth/", include("user.urls")),
    path("stores/", include("store.urls")),
    path("stores/", include("product.urls")),
    path("orders/", include("order.urls")),
    path("cart/", include("cart.urls")),
]
