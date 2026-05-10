"""
recommend/models.py

메인 서버(backend/)의 테이블을 읽기 전용으로 참조하는 모델.
managed = False → 마이그레이션 생성/실행 없이 기존 테이블을 그대로 사용.
필요한 필드만 선언하여 불필요한 JOIN 방지.
"""

from django.db import models


class LocationLog(models.Model):
    """
    backend/user/models/location_log.py 의 location_log 테이블 참조
    """
    log_id  = models.BigAutoField(primary_key=True, db_column="log_id")
    # user_id FK는 JOIN 없이 정수값만 읽음
    user_id = models.BigIntegerField(db_column="user_id")
    lat     = models.FloatField(db_column="lat")
    lon     = models.FloatField(db_column="lon")
    reg_dt  = models.DateTimeField(db_column="reg_dt")

    class Meta:
        managed  = False           # 마이그레이션 제외
        db_table = "location_log"


class Store(models.Model):
    """
    backend/store/models/store.py 의 store 테이블 참조
    추천에 필요한 필드만 선언
    """
    store_id      = models.BigAutoField(primary_key=True, db_column="store_id")
    store_name    = models.CharField(max_length=20,  db_column="store_name")
    store_address = models.CharField(max_length=100, db_column="store_address")
    store_lat     = models.FloatField(null=True,     db_column="store_lat")
    store_long    = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, db_column="store_long"
    )
    is_closed   = models.BooleanField(db_column="is_closed")
    is_deleted  = models.BooleanField(db_column="is_deleted")

    class Meta:
        managed  = False
        db_table = "store"


class Product(models.Model):
    """
    backend/product/models/product.py 의 product 테이블 참조
    할인율 계산에 필요한 필드만 선언
    """
    product_id = models.BigAutoField(primary_key=True, db_column="product_id")
    store_id          = models.BigIntegerField(db_column="store_id")
    product_ori_price = models.IntegerField(null=True, db_column="product_ori_price")
    product_dis_price = models.IntegerField(null=True, db_column="product_dis_price")
    is_deleted = models.BooleanField(db_column="is_deleted")

    class Meta:
        managed = False
        db_table = "product"

class Order(models.Model):
    """
    backend/order/models/order.py 의 order 테이블 참조.
    연관 규칙 / 인기도 폴백에 필요한 필드만 선언.
    """
    order_id     = models.BigAutoField(primary_key=True, db_column="order_id")
    store_id     = models.BigIntegerField(db_column="store_id")
    user_id      = models.BigIntegerField(db_column="user_id")
    order_status = models.CharField(max_length=10, db_column="order_status")
    reg_dt       = models.DateTimeField(db_column="reg_dt")

    class Meta:
        managed  = False
        db_table = "order"


class OrderItem(models.Model):
    """
    backend/order/models/orderProdList.py 의 order_item 테이블 참조.
    """
    id               = models.BigAutoField(primary_key=True)
    order_id         = models.BigIntegerField(db_column="order_id")
    product_id       = models.BigIntegerField(db_column="product_id")
    order_prod_count = models.SmallIntegerField(db_column="order_prod_count")

    class Meta:
        managed  = False
        db_table = "order_item"


class ProductCategory(models.Model):
    """
    연관 규칙에서 product → category 조회용.
    """
    product_id  = models.BigAutoField(primary_key=True, db_column="product_id")
    store_id    = models.BigIntegerField(db_column="store_id")
    category_id = models.BigIntegerField(db_column="category_id")
    is_deleted  = models.BooleanField(db_column="is_deleted")

    class Meta:
        managed  = False
        db_table = "product"


class Favorite(models.Model):
    """
    backend/store/models/favorite.py 의 favorite 테이블 참조.
    인기도 폴백에서 즐겨찾기 수 집계용.
    """
    id       = models.BigAutoField(primary_key=True)
    user_id  = models.BigIntegerField(db_column="user_id")
    store_id = models.BigIntegerField(db_column="store_id")

    class Meta:
        managed  = False
        db_table = "favorite"