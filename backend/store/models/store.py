from django.db import models
from user.models.user import User

class Store(models.Model):
    store_id = models.BigAutoField(db_comment="매장 ID", db_column='store_id', primary_key=True)
    user_id = models.ForeignKey(User, on_delete=models.CASCADE, db_comment="유저 ID", db_column='user_id')
    store_img_id = models.ForeignKey(
        'image.Image',
        on_delete=models.SET_NULL,
        db_comment="매장 이미지 ID",
        db_column='store_img_id',
        null=True,
        blank=True,
    )
    store_name = models.CharField(db_comment="매장 이름", db_column="store_name", max_length=20)
    store_address = models.CharField(db_comment="매장 주소", db_column="store_address", max_length=100)
    store_desc = models.TextField(db_comment="매장 설명", db_column="store_desc", null=True)
    is_closed = models.BooleanField(db_comment="매장 마감 여부", db_column="is_closed", default=False )
    is_deleted = models.BooleanField(db_comment='삭제 여부', db_column='is_deleted', default=False )
    #store_lat = models.FloatField(db_comment="매장 위도", db_column="store_lat", null=True)
    # 더욱 정확함 위할 시 위도도 decimal로 수정 가능
    store_lat = models.DecimalField(db_comment="매장 위도", db_column="store_lat", max_digits=10, decimal_places=7, null=True)
    store_long = models.DecimalField(db_comment="매장 경도", db_column="store_long", max_digits=11, decimal_places=7, null=True)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "store"
        db_table_comment = '매장 테이블'
