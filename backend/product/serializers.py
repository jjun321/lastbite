from rest_framework import serializers
from product.models.product import Product
from product.models.category import Category


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