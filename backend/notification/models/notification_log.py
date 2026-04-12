from django.db import models

from notification.models.choices import TARGET_TYPE_CHOICE


class NotificationLog(models.Model):
    """
    실제 알림 발송 이력 테이블
    - notification_id: 어떤 알림 설정에서 발생했는지 (수신자 기준)
    - target_id / target_type: 알림 대상 (주문번호, 매장ID 등)
    - is_read: 읽음 처리 여부
    """
    log_id = models.BigAutoField(
        db_comment="알림 로그 ID",
        db_column="log_id",
        primary_key=True,
    )
    notification_id = models.ForeignKey(
        "notification.Notification",
        on_delete=models.CASCADE,
        db_comment="알림 ID",
        db_column="notification_id",
        related_name="logs",
    )
    user_id = models.ForeignKey(
        "user.User",
        on_delete=models.CASCADE,
        db_comment="수신 유저 ID",
        db_column="user_id",
        related_name="notification_logs",
    )
    target_id = models.BigIntegerField(
        db_comment="대상 ID (주문번호, 매장ID 등)",
        db_column="target_id",
        null=True,
    )
    target_type = models.CharField(
        db_comment="대상 타입",
        db_column="target_type",
        max_length=10,
        choices=TARGET_TYPE_CHOICE,
        null=True,
    )
    is_read = models.BooleanField(
        db_comment="읽음 여부",
        db_column="is_read",
        default=False,
    )
    reg_dt = models.DateTimeField(
        db_comment="생성 일시",
        db_column="reg_dt",
        auto_now_add=True,
    )

    class Meta:
        db_table = "notification_log"
        db_table_comment = "알림 로그"
        ordering = ["-reg_dt"]
