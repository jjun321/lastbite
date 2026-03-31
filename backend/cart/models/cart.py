from django.db import models


class Cart(models.Model):
    cart_id = models.BigAutoField(db_comment="장바구니 ID", db_column='cart_id', primary_key=True)
    user_id = models.OneToOneField(
        'user.User',
        on_delete=models.CASCADE,
        db_comment="유저 ID",
        db_column='user_id',
    )
    store_id = models.ForeignKey(
        'store.Store',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_comment="매장 ID",
        db_column='store_id',
    )
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = 'cart'
        db_table_comment = '장바구니 테이블'
