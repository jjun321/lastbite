from django.db import models

from store.models.store import Store
from user.models.user import User

class OffDate(models.Model):
    closed_date_id = models.BigAutoField(db_comment="휴무 테이블 ID", db_column='closed_date_id', primary_key=True)
    user_id = models.ForeignKey(User,on_delete=models.CASCADE,db_comment="유저 ID", db_column='user_id')
    store_id = models.ForeignKey(Store,on_delete=models.CASCADE,db_comment="매장 ID", db_column='store_id')
    off_dt = models.DateField(db_comment="휴무 예약일", db_column="off_dt", blank=False, null=False)
    off_desc = models.TextField(db_comment="휴무 사유", db_column="off_desc", blank=True, null=True )
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "off_date"
        db_table_comment = '매장 휴무 예약 테이블'