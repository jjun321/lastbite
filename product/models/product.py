from django.db import models

class Product(models.Model):
    product_id = models.BigAutoField(db_comment="제품 ID", db_column='product_id', primary_key=True)

    #아직 완성 안됐으므로 외래키는 주석처리
    #market = models.ForeignKey('market.Market', on_delete=models.CASCADE, db_comment="매장 ID", db_column='market_id')
    #category = models.ForeignKey('product.Category', on_delete=models.CASCADE, db_comment="카테고리 ID", db_column='category_id')

    market_id = models.IntegerField(db_comment="매장 ID", db_column='market_id', null=True)
    category_id = models.IntegerField(db_comment="카테고리 ID", db_column='category_id', null=True)
    product_name = models.CharField(db_comment="제품 이름", db_column='product_name', max_length=30)
    product_desc = models.TextField(db_comment="제품 설명", db_column='product_desc', null=True)
    product_stock = models.SmallIntegerField(db_comment="제품 재고", db_column='product_stock',null=True)
    product_dis_price = models.IntegerField(db_comment="제품 할인 후 가격", db_column='product_dis_price', null=True)
    product_ori_price = models.IntegerField(db_comment="제품 할인 전 가격", db_column='product_ori_price', null=True)
    product_freshness = models.IntegerField(db_comment="제품 신선도", db_column='product_freshness', null=True)

    is_deleted = models.BooleanField(db_comment="삭제 여부", db_column='is_deleted', default=False)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "product"
        db_table_comment = '제품 정의 테이블'
