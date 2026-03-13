from django.db import models

from product.models import Product


class ProductImg(models.Model):
    product_id = models.IntegerField(db_comment='제품 ID',db_column='product_id')
    img_id = models.IntegerField(db_comment='이미지 ID',db_column='img_id')

    class Meta:
        db_table = "제품 이미지 테이블"