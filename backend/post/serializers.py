from rest_framework import serializers
from post.models.post import Post

from store.utils import haversine_km


class PostResponseSerializer(serializers.ModelSerializer):
    #제보 목록/상세/생성 공통 응답 직렬화
    user_id    = serializers.IntegerField(source='user_id_id')
    user_name  = serializers.CharField(source='user_id.user_name')
    post_lat = serializers.FloatField()
    post_long = serializers.FloatField()
    store_id   = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()
    img_url    = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()
    reg_dt     = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")

    class Meta:
        model  = Post
        fields = [
            'post_id', 'user_id', 'user_name', 'post_name',
            'content', 'post_lat', 'post_long',
            'store_id', 'store_name',
            'img_url', 'distance_km', 'reg_dt',
        ]
    def get_distance_km(self, obj):
        ref_lat = self.context.get('ref_lat')
        ref_long = self.context.get('ref_long')
        if ref_lat is None or ref_long is None:
            return None
        if obj.post_lat is None or obj.post_long is None:
            return None
        return round(haversine_km(ref_lat, ref_long, float(obj.post_lat), float(obj.post_long)), 2)

    def get_store_id(self, obj):
        return obj.store_id_id if obj.store_id_id else None

    def get_store_name(self, obj):
        return obj.store_id.store_name if obj.store_id else None

    def get_img_url(self, obj):
        return obj.img_id.img_url if obj.img_id else None