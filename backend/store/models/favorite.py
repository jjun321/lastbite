from django.db import models
from user.models.user import User
from store.models.store import Store


class Favorite(models.Model):
    user_id = models.ForeignKey(
        User, on_delete=models.CASCADE,
        db_comment="소비자 ID", db_column='user_id'
    )
    store_id = models.ForeignKey(
        Store, on_delete=models.CASCADE,
        db_comment="매장 ID", db_column='store_id'
    )
    reg_dt = models.DateTimeField(
        db_comment="생성 일자", db_column='reg_dt', auto_now_add=True
    )

    class Meta:
        db_table = "favorite"
        db_table_comment = '즐겨찾기 테이블'
        unique_together = ('user_id', 'store_id')