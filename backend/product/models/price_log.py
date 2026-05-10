"""
product/models/price_log.py
가격 로그 테이블 — 제품 등록/수정 시마다 가격 이력 저장
discount_rate는 저장 시점에 계산해서 채워 넣음
"""

from django.db import models


class PriceLog(models.Model):
    log_id = models.BigAutoField(
        db_comment="로그 ID", db_column="log_id", primary_key=True
    )
    product_id = models.ForeignKey(
        "product.Product",
        on_delete=models.CASCADE,
        db_comment="제품 ID",
        db_column="product_id",
        related_name="price_logs",
    )
    store_id = models.ForeignKey(
        "store.Store",
        on_delete=models.CASCADE,
        db_comment="매장 ID",
        db_column="store_id",
    )
    owner_id = models.ForeignKey(
        "user.User",
        on_delete=models.CASCADE,
        db_comment="점주 ID",
        db_column="owner_id",
    )
    product_dis_price = models.IntegerField(
        db_comment="제품 할인 후 가격", db_column="product_dis_price", null=True
    )
    product_ori_price = models.IntegerField(
        db_comment="제품 할인 전 가격", db_column="product_ori_price", null=True
    )
    discount_rate = models.IntegerField(
        db_comment="제품 할인율 (%)", db_column="discount_rate", null=True
    )
    reg_dt = models.DateTimeField(
        db_comment="생성 일자", db_column="reg_dt", auto_now_add=True
    )

    class Meta:
        db_table = "price_log"
        db_table_comment = "가격 로그 테이블"
        ordering = ["-reg_dt"]

    def save(self, *args, **kwargs):
        """discount_rate를 저장 시 자동 계산"""
        if self.product_ori_price and self.product_ori_price > 0:
            self.discount_rate = int(
                (1 - self.product_dis_price / self.product_ori_price) * 100
            )
        else:
            self.discount_rate = None
        super().save(*args, **kwargs)
