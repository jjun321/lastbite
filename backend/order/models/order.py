from django.db import models
from order.models.choices import ORDER_STATUS_CHOICE

class Order(models.Model):
    order_id = models.BigAutoField(db_comment="주문 번호", db_column='order_id', primary_key=True)
    store_id = models.ForeignKey('store.Store', on_delete=models.CASCADE, db_comment="매장 ID", db_column='store_id')
    user_id = models.ForeignKey('user.User', on_delete=models.CASCADE, db_comment="소비자 ID", db_column='user_id')
    order_status = models.CharField(db_comment="주문 상태", db_column='order_status', max_length=10, choices=ORDER_STATUS_CHOICE)
    pickup_dt = models.DateTimeField(db_comment="픽업 일시", db_column='pickup_dt', null=True)
    reg_dt = models.DateTimeField(db_comment="주문 일시", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "order"
        db_table_comment = '주문 테이블 정의'