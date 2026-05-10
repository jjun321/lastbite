from django.db import models
from user.models.user import User


class LocationLog(models.Model):
    log_id = models.BigAutoField(
        db_comment="위치 로그 ID", db_column='log_id', primary_key=True
    )
    user_id = models.ForeignKey(
        User, on_delete=models.CASCADE,
        db_comment="유저 ID", db_column='user_id'
    )
    lat = models.FloatField(
        db_comment="위치 위도", db_column='lat'
    )
    lon = models.FloatField(
        db_comment="위치 경도", db_column='lon'
    )
    reg_dt = models.DateTimeField(
        db_comment="저장 일시", db_column='reg_dt', auto_now_add=True
    )

    class Meta:
        db_table = "location_log"
        db_table_comment = '사용자 위치 로그 테이블'
        ordering = ['-reg_dt']