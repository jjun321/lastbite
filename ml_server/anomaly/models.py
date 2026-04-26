from django.db import models

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