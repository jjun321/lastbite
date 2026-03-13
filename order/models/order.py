from django.db import models
from order.models.choices import ORDER_STATUS_CHOICE

class Order(models.Model):
    order_id = models.BigAutoField(db_comment="주문 번호", db_column='order_id', primary_key=True)
    #아직 완성되지 않았기에 외래키는 임시로 주석처리
    #store = models.ForeignKey('store.Store', on_delete=models.CASCADE, db_comment="매장 ID", db_column='store_id')
    #customer = models.ForeignKey('user.User', on_delete=models.CASCADE, db_comment="소비자 ID", db_column='customer_id')

    store = models.IntegerField(db_comment="매장 ID", db_column='store_id', null=True)
    customer = models.IntegerField(db_comment="소비자 ID", db_column='customer_id', null=True)
    order_status = models.CharField(db_comment="주문 상태", db_column='order_status', max_length=15, choices=ORDER_STATUS_CHOICE, default='CREATED')
    pickup_dt = models.DateTimeField(db_comment="픽업 일시", db_column='pickup_dt', null=True)
    reg_dt = models.DateTimeField(db_comment="주문 일시", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "order"
        db_table_comment = '주문 테이블 정의'