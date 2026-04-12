from rest_framework import serializers

from notification.models.notification import Notification
from notification.models.notification_log import NotificationLog


class NotificationSettingSerializer(serializers.ModelSerializer):
    """알림 설정 조회용 (GET /notifications/settings/)"""

    class Meta:
        model = Notification
        fields = ["notification_id", "notification_type", "is_active"]
        read_only_fields = ["notification_id", "notification_type"]


class NotificationSettingUpdateSerializer(serializers.Serializer):
    """알림 설정 변경용 (PATCH /notifications/settings/)"""

    settings = serializers.ListField(
        child=serializers.DictField(), allow_empty=False
    )

    def validate_settings(self, value):
        valid_types = {"N01", "N02", "N03", "N04"}
        for item in value:
            if "notification_type" not in item or "is_active" not in item:
                raise serializers.ValidationError(
                    "각 항목에 notification_type 과 is_active 가 필요합니다."
                )
            if item["notification_type"] not in valid_types:
                raise serializers.ValidationError(
                    f"유효하지 않은 알림 타입입니다: {item['notification_type']}"
                )
            if not isinstance(item["is_active"], bool):
                raise serializers.ValidationError("is_active 는 boolean 이어야 합니다.")
        return value


class NotificationLogSerializer(serializers.ModelSerializer):
    """알림 로그 목록 조회용 (GET /notifications/)"""

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
