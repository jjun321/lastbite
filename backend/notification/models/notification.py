from django.db import models

from notification.models.choices import NOTIFICATION_TYPE_CHOICE


class Notification(models.Model):
    """
    유저별 알림 수신 설정 테이블
    - 알림 타입(N01~N04)별로 ON/OFF 관리
    - 유저 등록 시 기본 행 생성 (utils.py의 create_default_notification_settings 참고)
    """
    notification_id = models.BigAutoField(
        db_comment="알림 ID",
        db_column="notification_id",
        primary_key=True,
    )
    user_id = models.ForeignKey(
        "user.User",
        on_delete=models.CASCADE,
        db_comment="유저 ID",
        db_column="user_id",
        related_name="notifications",
    )
    notification_type = models.CharField(
        db_comment="알림 타입",
        db_column="notification_type",
        max_length=10,
        choices=NOTIFICATION_TYPE_CHOICE,
    )
    is_active = models.BooleanField(
        db_comment="알림 수신 여부 (토글)",
        db_column="is_active",
        default=True,
    )

    class Meta:
        db_table = "notification"
        db_table_comment = "알림 테이블"
        unique_together = ("user_id", "notification_type")
