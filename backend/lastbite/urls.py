from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from user.urls import users_urlpatterns

def home(request):
    return JsonResponse({"message": "backend test"})

urlpatterns = [
    path("", home),
    path("admin/", admin.site.urls),
    path("auth/", include("user.urls")),
    path("users/", include((users_urlpatterns, "users"))),
    path("stores/", include("store.urls")),
    path("stores/", include("product.urls")),
    path("orders/", include("order.urls")),
    path("cart/", include("cart.urls")),
    path("notifications/", include("notification.urls")),
    path("owner/stores/", include("store.owner_urls")),
]

#개발환경에서 미디어 파일 제공을 위한 코드, 임시 사용 코드이기에 일단 주석처리함

#from django.conf import settings
#from django.conf.urls.static import static

#if settings.DEBUG:
#    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
