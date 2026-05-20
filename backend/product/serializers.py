from rest_framework import serializers
from product.models.product import Product
from product.models.category import Category
from store.utils import haversine_km

class ProductListSerializer(serializers.ModelSerializer):
    #GET /stores/{store_id}/products/
    product_id = serializers.IntegerField(source='pk')
    category_id = serializers.SerializerMethodField()
    category_name = serializers.SerializerMethodField()
    discount_rate = serializers.SerializerMethodField()
    img_url = serializers.SerializerMethodField()
    is_available = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'product_id',
            'category_id',
            'category_name',
            'product_name',
            'product_desc',
            'product_ori_price',
            'product_dis_price',
            'discount_rate',
            'product_count',
            'img_url',
            'is_available',
        ]

    def get_category_id(self, obj):
        return obj.category_id.category_id if obj.category_id else None

    def get_category_name(self, obj):
        return obj.category_id.category_name if obj.category_id else None

    def get_discount_rate(self, obj):
        ori = obj.product_ori_price or 0
        dis = obj.product_dis_price or 0
        if ori == 0:
            return 0
        return int((1 - dis / ori) * 100)

    def get_img_url(self, obj):
        # Image 테이블 조인
        product_img = obj.productimg_set.select_related('img_id').first()
        if not product_img:
            return None
        return product_img.img_id.img_url

    def get_is_available(self, obj):
        return (obj.product_count or 0) > 0


class CategoryListSerializer(serializers.ModelSerializer):
    category_id = serializers.IntegerField(source='pk')

    class Meta:
        model = Category
        fields = [
            'category_id',
            'category_name'
        ]


class ProductSearchSerializer(serializers.ModelSerializer):
    """
    GET /products/search/ 응답.
    기존 ProductListSerializer에 매장 정보 + 거리 + 이상치 플래그 추가.
    """
    product_id    = serializers.IntegerField(source='pk')
    category_name = serializers.CharField(source='category_id.category_name', default=None)
    discount_rate = serializers.SerializerMethodField()
    img_url       = serializers.SerializerMethodField()
    is_available  = serializers.SerializerMethodField()
    store_id      = serializers.IntegerField(source='store_id_id')
    store_name    = serializers.CharField(source='store_id.store_name')
    store_address = serializers.CharField(source='store_id.store_address')
    distance_km   = serializers.SerializerMethodField()
    # 이상치 탐지 결과 플래그
    is_special    = serializers.SerializerMethodField()
    # 주문이력 기반 상단 노출 플래그 (context에서 주입)
    is_preferred  = serializers.SerializerMethodField()

    class Meta:
        model  = Product
        fields = [
            'product_id', 'product_name', 'product_desc',
            'category_name',
            'product_ori_price', 'product_dis_price', 'discount_rate',
            'product_count', 'img_url', 'is_available',
            'store_id', 'store_name', 'store_address', 'distance_km',
            'is_special', 'is_preferred',
        ]

    def get_discount_rate(self, obj):
        ori = obj.product_ori_price or 0
        dis = obj.product_dis_price or 0
        return int((1 - dis / ori) * 100) if ori else 0

    def get_img_url(self, obj):
        pi = obj.productimg_set.select_related('img_id').first()
        return pi.img_id.img_url if pi else None

    def get_is_available(self, obj):
        return (obj.product_count or 0) > 0

    def get_distance_km(self, obj):
        ref_lat = self.context.get('ref_lat')
        ref_lon = self.context.get('ref_lon')
        if ref_lat is None or ref_lon is None:
            return None
        s = obj.store_id
        if not s.store_lat or not s.store_long:
            return None
        return round(haversine_km(ref_lat, ref_lon, float(s.store_lat), float(s.store_long)), 2)

    def get_is_special(self, obj):
        """
        이상치 탐지 HIGH 판정 상품 여부.
        views.py에서 anomaly_map = {product_id: bool} 형태로 context에 주입.
        """
        anomaly_map = self.context.get('anomaly_map', {})
        return anomaly_map.get(obj.pk, False)

    def get_is_preferred(self, obj):
        """
        유저가 이미 주문한 카테고리 소속 상품 여부.
        views.py에서 preferred_category_ids = set() 형태로 context에 주입.
        """
        preferred = self.context.get('preferred_category_ids', set())
        if not preferred:
            return False
        cat = obj.category_id
        return (cat.category_id if cat else None) in preferred


class HotDealSerializer(serializers.Serializer):
    """
    GET /products/hotdeal/ 응답.
    Serializer 기반으로 재작성하여 views.py 코드 단순화.
    """
    product_id        = serializers.IntegerField()
    product_name      = serializers.CharField()
    product_ori_price = serializers.IntegerField()
    product_dis_price = serializers.IntegerField()
    discount_rate     = serializers.IntegerField()
    img_url           = serializers.CharField(allow_null=True)
    is_special        = serializers.BooleanField()   # 이상치 HIGH
    is_preferred      = serializers.BooleanField()   # 유저 주문 카테고리 소속
    store_id          = serializers.IntegerField()
    store_name        = serializers.CharField()
    store_address     = serializers.CharField()
    store_lat         = serializers.FloatField(allow_null=True)
    store_lon         = serializers.FloatField(allow_null=True)


class CategoryListSerializer(serializers.ModelSerializer):
    category_id = serializers.IntegerField(source='pk')

    class Meta:
        model  = Category
        fields = ['category_id', 'category_name']