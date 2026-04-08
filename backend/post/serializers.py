from rest_framework import serializers
from post.models.post import Post


class PostResponseSerializer(serializers.ModelSerializer):
    #제보 목록/상세/생성 공통 응답 직렬화
    user_id    = serializers.IntegerField(source='user_id_id')
    user_name  = serializers.CharField(source='user_id.user_name')
    store_id   = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()
    img_url    = serializers.SerializerMethodField()
    reg_dt     = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")

    class Meta:
        model  = Post
        fields = [
            'post_id', 'user_id', 'user_name', 'post_name',
            'content', 'post_lat', 'post_long',
            'store_id', 'store_name',
            'img_url', 'reg_dt',
        ]

    def get_store_id(self, obj):
        return obj.store_id_id if obj.store_id_id else None

    def get_store_name(self, obj):
        return obj.store_id.store_name if obj.store_id else None

    def get_img_url(self, obj):
        return obj.img_id.img_url if obj.img_id else None