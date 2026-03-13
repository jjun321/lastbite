from django.db import models

class OrderProdList(models.Model):
    # 아직 완성되지 않았기에 외래키는 임시로 주석처리
    #order = models.ForeignKey('order.Order', on_delete=models.CASCADE, db_comment="주문 번호", db_column='order_id')
    #product = models.ForeignKey('product.Product', on_delete=models.CASCADE, db_comment="제품 ID", db_column='product_id')
    order = models.IntegerField(db_comment="주문 번호", db_column='order_id', )
    product = models.IntegerField(db_comment="제품 ID", db_column='product_id')
    order_prod_count = models.SmallIntegerField(db_comment="주문한 제품 개수", db_column='order_prod_count')
    product_dis_price = models.IntegerField(db_comment="제품 할인 후 가격", db_column='product_dis_price')
    product_ori_price = models.IntegerField(db_comment="제품 할인 전 가격", db_column='product_ori_price')

    class Meta:
        db_table = "order_item"
        db_table_comment = '주문한 제품 상세 테이블'