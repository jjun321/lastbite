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


class PriceLog(models.Model):
    """
    backend/product/models/price_log.py 의 price_log 테이블 참조
    Isolation Forest 학습 데이터 소스
    """
    log_id            = models.BigAutoField(primary_key=True, db_column="log_id")
    product_id        = models.BigIntegerField(db_column="product_id")
    store_id          = models.BigIntegerField(db_column="store_id")
    owner_id          = models.BigIntegerField(db_column="owner_id")
    product_dis_price = models.IntegerField(null=True, db_column="product_dis_price")
    product_ori_price = models.IntegerField(null=True, db_column="product_ori_price")
    discount_rate     = models.IntegerField(null=True, db_column="discount_rate")
    reg_dt            = models.DateTimeField(db_column="reg_dt")

    class Meta:
        managed  = False
        db_table = "price_log"
