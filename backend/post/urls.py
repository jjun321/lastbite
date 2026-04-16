from django.urls import path
from post.views import PostListView, PostDetailView

urlpatterns = [
    path('', PostListView.as_view(), name='post-list-create'),
    path('<int:post_id>/', PostDetailView.as_view(), name='post-detail-delete'),
]