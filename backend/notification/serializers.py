from rest_framework import serializers

from notification.models.choices import NOTIFICATION_TYPE_CHOICE
from notification.models.notification import Notification
from notification.models.notification_log import NotificationLog


# ── 알림 설정 조회 ────────────────────────────────────────────────────────────

class NotificationSettingSerializer(serializers.ModelSerializer):
    """GET /notifications/settings/"""

    class Meta:
        model = Notification
        fields = ["notification_id", "notification_type", "is_active"]
        read_only_fields = ["notification_id", "notification_type"]


# ── 알림 설정 변경 ────────────────────────────────────────────────────────────

class NotificationSettingItemSerializer(serializers.Serializer):
    """settings 배열의 각 항목 유효성 검사"""
    VALID_TYPES = {code for code, _ in NOTIFICATION_TYPE_CHOICE}

    notification_type = serializers.ChoiceField(choices=NOTIFICATION_TYPE_CHOICE)
    is_active = serializers.BooleanField()


class NotificationSettingUpdateSerializer(serializers.Serializer):
    """PATCH /notifications/settings/"""
    settings = NotificationSettingItemSerializer(many=True, allow_empty=False)


# ── 알림 로그 조회 ────────────────────────────────────────────────────────────

class NotificationLogSerializer(serializers.ModelSerializer):
    """GET /notifications/"""
    # notification_id FK에서 타입 코드만 꺼내서 노출
    notification_type = serializers.CharField(
        source="notification_id.notification_type"
    )

    class Meta:
        model = NotificationLog
        fields = [
            "log_id",
            "notification_type",
            "target_id",
            "target_type",
            "is_read",
            "reg_dt",
        ]
