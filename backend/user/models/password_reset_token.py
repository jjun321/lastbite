import uuid
from django.db import models
from user.models.user import User


class PasswordResetToken(models.Model):
    token_id = models.BigAutoField(
        db_comment="토큰 ID", db_column='token_id', primary_key=True
    )
    user_id = models.ForeignKey(
        User, on_delete=models.CASCADE,
        db_comment="유저 ID", db_column='user_id'
    )
    token = models.UUIDField(
        db_comment="재설정 토큰 (UUID)", db_column='token',
        default=uuid.uuid4, unique=True
    )
    is_used = models.BooleanField(
        db_comment="사용 여부", db_column='is_used', default=False
    )
    expired_at = models.DateTimeField(
        db_comment="만료 일시", db_column='expired_at'
    )
    reg_dt = models.DateTimeField(
        db_comment="생성 일자", db_column='reg_dt', auto_now_add=True
    )

    class Meta:
        db_table = "password_reset_token"
        db_table_comment = '비밀번호 재설정 토큰 테이블'