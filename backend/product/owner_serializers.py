import uuid
import os

from django.conf import settings
from rest_framework import serializers

from product.models.product import Product
from product.models.category import Category
from product.models.productImg import ProductImg
from image.models.image import Image


class OwnerProductListSerializer(serializers.ModelSerializer):
    """GET /owner/stores/{store_id}/products/ — 판매설정 화면 상품 목록"""
    product_id     = serializers.IntegerField(source='pk')
    category_id    = serializers.IntegerField(source='category_id.category_id', default=None)
    category_name  = serializers.CharField(source='category_id.category_name', default=None)
    discount_rate  = serializers.SerializerMethodField()
    img_url        = serializers.SerializerMethodField()
    is_available   = serializers.SerializerMethodField()

    class Meta:
        model  = Product
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

    def get_discount_rate(self, obj):
        ori = obj.product_ori_price or 0
        dis = obj.product_dis_price or 0
        if ori == 0:
            return 0
        return int((1 - dis / ori) * 100)

    def get_img_url(self, obj):
        pi = obj.productimg_set.select_related('img_id').first()
        return pi.img_id.img_url if pi else None

    def get_is_available(self, obj):
        return (obj.product_count or 0) > 0


class OwnerProductCreateSerializer(serializers.Serializer):
    """POST /owner/stores/{store_id}/products/ — 상품 등록"""
    product_name    = serializers.CharField(max_length=30)
    category_id     = serializers.IntegerField()
    product_ori_price = serializers.IntegerField(min_value=0)
    product_dis_price = serializers.IntegerField(min_value=0)
    product_count   = serializers.IntegerField(min_value=0, default=0)
    product_desc    = serializers.CharField(required=False, allow_blank=True, default=None)
    image_file      = serializers.ImageField(required=False, allow_null=True)

    def validate(self, data):
        if data['product_dis_price'] > data['product_ori_price']:
            raise serializers.ValidationError(
                {"product_dis_price": "할인가는 정가보다 클 수 없습니다."}
            )
        return data

    def validate_category_id(self, value):
        if not Category.objects.filter(category_id=value, is_deleted=False).exists():
            raise serializers.ValidationError("존재하지 않는 카테고리입니다.")
        return value


class OwnerProductUpdateSerializer(serializers.Serializer):
    """PATCH /owner/stores/{store_id}/products/{product_id}/ — 상품 수정 (모든 필드 optional)"""
    product_name      = serializers.CharField(max_length=30, required=False)
    category_id       = serializers.IntegerField(required=False)
    product_ori_price = serializers.IntegerField(min_value=0, required=False)
    product_dis_price = serializers.IntegerField(min_value=0, required=False)
    product_count     = serializers.IntegerField(min_value=0, required=False)
    product_desc      = serializers.CharField(required=False, allow_blank=True)
    image_file        = serializers.ImageField(required=False, allow_null=True)

    def validate(self, data):
        ori = data.get('product_ori_price')
        dis = data.get('product_dis_price')
        if ori is not None and dis is not None and dis > ori:
            raise serializers.ValidationError(
                {"product_dis_price": "할인가는 정가보다 클 수 없습니다."}
            )
        return data

    def validate_category_id(self, value):
        if not Category.objects.filter(category_id=value, is_deleted=False).exists():
            raise serializers.ValidationError("존재하지 않는 카테고리입니다.")
        return value