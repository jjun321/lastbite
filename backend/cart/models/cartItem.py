from django.db import models


class CartItem(models.Model):
    cart_item_id = models.BigAutoField(db_comment="장바구니 상품 ID", db_column='cart_item_id', primary_key=True)
    cart_id = models.ForeignKey(
        'cart.Cart',
        on_delete=models.CASCADE,
        db_comment="장바구니 ID",
        db_column='cart_id',
        related_name='items',
    )
    product_id = models.ForeignKey(
        'product.Product',
        on_delete=models.CASCADE,
        db_comment="제품 ID",
        db_column='product_id',
    )
    quantity = models.IntegerField(db_comment="담은 수량", db_column='quantity')
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = 'cart_item'
        db_table_comment = '장바구니 상품 테이블'
