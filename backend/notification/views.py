from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from common.response import error_response, extract_first_error, success_response
from notification.models.choices import NOTIFICATION_TYPE_CHOICE
from notification.models.notification import Notification
from notification.models.notification_log import NotificationLog
from notification.serializers import (
    NotificationLogSerializer,
    NotificationSettingSerializer,
    NotificationSettingUpdateSerializer,
)
from notification.utils import create_default_notification_settings


class NotificationSettingsView(APIView):
    """
    GET  /notifications/settings/ — 내 알림 설정 목록 조회
    PATCH /notifications/settings/ — 알림 설정 일괄 변경
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 설정 행이 없는 경우 기본값 생성 (안전망)
        existing_types = set(
            Notification.objects.filter(user_id=request.user)
            .values_list("notification_type", flat=True)
        )
        all_types = {code for code, _ in NOTIFICATION_TYPE_CHOICE}
        missing = all_types - existing_types
        if missing:
            Notification.objects.bulk_create(
                [
                    Notification(
                        user_id=request.user,
                        notification_type=t,
                        is_active=True,
                    )
                    for t in missing
                ],
                ignore_conflicts=True,
            )

        settings = Notification.objects.filter(user_id=request.user).order_by(
            "notification_type"
        )
        serializer = NotificationSettingSerializer(settings, many=True)
        return success_response(data=serializer.data)

    def patch(self, request):
        serializer = NotificationSettingUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(
                message=extract_first_error(serializer.errors),
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        updated = []
        for item in serializer.validated_data["settings"]:
            pref, _ = Notification.objects.get_or_create(
                user_id=request.user,
                notification_type=item["notification_type"],
                defaults={"is_active": item["is_active"]},
            )
            if pref.is_active != item["is_active"]:
                pref.is_active = item["is_active"]
                pref.save(update_fields=["is_active"])
            updated.append(
                {
                    "notification_type": pref.notification_type,
                    "is_active": pref.is_active,
                }
            )

        return success_response(data=updated)


class NotificationLogView(APIView):
    """
    GET   /notifications/        — 내 알림 로그 목록 조회
    PATCH /notifications/read/   — 알림 전체 읽음 처리
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        page = int(request.query_params.get("page", 0))
        size = int(request.query_params.get("size", 20))

        logs = NotificationLog.objects.filter(user_id=request.user).select_related(
            "notification_id"
        )
        total = logs.count()
        paged = logs[page * size : (page + 1) * size]

        serializer = NotificationLogSerializer(paged, many=True)
        return success_response(
            data={
                "total": total,
                "page": page,
                "size": size,
                "notifications": serializer.data,
            }
        )


class NotificationReadAllView(APIView):
    """
    PATCH /notifications/read/ — 내 알림 전체 읽음 처리
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        updated_count = NotificationLog.objects.filter(
            user_id=request.user, is_read=False
        ).update(is_read=True)

        return success_response(
            data={"updated_count": updated_count},
            message=f"{updated_count}개의 알림을 읽음 처리했습니다.",
        )
