from django.db import models
from user.models.user import User

class Store(models):
    store_id = models.BigAutoField(db_comment="매장 ID", db_column='store_id', primary_key=True)
    user_id = models.ForeignKey(User,on_delete=models.CASCADE,db_comment="유저 ID", db_column='user_id')
    store_name = models.CharField(db_comment="매장 이름", db_column="store_name", max_length=20)
    store_address = models.CharField(db_comment="매장 주소", db_column="store_address", max_length=100)
    is_closed = models.BooleanField(db_comment="매장 마감 여부", db_column="is_closed", default=False )
    is_deleted = models.BooleanField(db_comment='삭제 여부', db_column='is_deleted', default=False )
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "store"
        db_table_comment = '매장 테이블'
