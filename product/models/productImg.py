from django.db import models

from product.models import Product


class ProductImg(models.Model):
    product_id = models.ForeignKey('product.Product', on_delete=models.CASCADE, db_comment="매장 ID", db_column='product_id')
    img_id = models.ForeignKey('image.Image', on_delete=models.CASCADE, db_comment="카테고리 ID", db_column='img_id')

    class Meta:
        db_table = "제품 이미지 테이블"