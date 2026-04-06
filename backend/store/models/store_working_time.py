from django.db import models

from store.models.store import Store
from user.models.user import User

class StoreWorkingTime(models.Model):
    working_time_id = models.BigAutoField(db_comment="매장 운영시간 ID", db_column='working_time_id', primary_key=True)
    store_id = models.ForeignKey(Store,on_delete=models.CASCADE,db_comment="매장 ID", db_column='store_id')
    working_day = models.TextField(db_comment="매장 운영 요일", db_column="working_day", max_length=10)
    start_time = models.TimeField(db_comment="매장 운영 시작 시간", db_column="start_time", null=False)
    end_time = models.TimeField(db_comment="매장 마감 시간", db_column='end_time', null=False)

    class Meta:
        db_table = "store_working_time"
        db_table_comment = '매장 운영시간 테이블'