"""
notification/utils.py

알림 관련 공통 헬퍼 함수 모음.
- 유저 등록 시 기본 알림 설정 생성
- 주문·매장 이벤트 발생 시 알림 로그 생성
"""
from notification.models.notification import Notification
from notification.models.notification_log import NotificationLog
from notification.models.choices import NOTIFICATION_TYPE_CHOICE


# ── 기본 알림 설정 생성 ──────────────────────────────────────────────────────

def create_default_notification_settings(user):
    """
    회원가입 시 모든 알림 타입에 대해 기본 설정 행 생성 (is_active=True)
    RegisterView에서 user.save() 이후 호출
    """
    Notification.objects.bulk_create([
        Notification(user_id=user, notification_type=code, is_active=True)
        for code, _ in NOTIFICATION_TYPE_CHOICE
    ], ignore_conflicts=True)


# ── 알림 로그 생성 ───────────────────────────────────────────────────────────

def _get_or_create_pref(user, notification_type):
    """
    유저의 특정 알림 타입 설정 행을 조회하거나 없으면 생성
    - 설정 행이 없는 유저(구버전 가입자 등)에 대한 안전망
    """
    pref, _ = Notification.objects.get_or_create(
        user_id=user,
        notification_type=notification_type,
        defaults={"is_active": True},
    )
    return pref


def create_notification_log(receiver, notification_type, target_id=None, target_type=None):
    """
    알림 로그를 생성하는 공통 함수.

    Args:
        receiver          : 알림 수신 User 객체
        notification_type : 'N01' ~ 'N04'
        target_id         : 알림 대상 PK (주문번호, 매장ID 등)
        target_type       : 'ORDER' | 'STORE' | 'PRODUCT'

    Returns:
        NotificationLog 객체 또는 None (알림이 꺼져있으면 생성 안 함)
    """
    pref = _get_or_create_pref(receiver, notification_type)

    # 알림 수신 OFF 상태면 로그 생성 안 함
    if not pref.is_active:
        return None

    return NotificationLog.objects.create(
        notification_id=pref,
        user_id=receiver,
        target_id=target_id,
        target_type=target_type,
    )


# ── 주문 관련 알림 헬퍼 ──────────────────────────────────────────────────────

def notify_order_received(order):
    """
    N01: 주문 접수 → 점주에게 알림
    주문 생성(S01) 시 호출
    Store.user_id 가 점주 FK
    """
    store_owner = order.store_id.user_id  # Store.user_id → 점주 User
    create_notification_log(
        receiver=store_owner,
        notification_type="N01",
        target_id=order.order_id,
        target_type="ORDER",
    )


def notify_order_completed(order):
    """
    N02: 주문 처리 완료 → 소비자에게 알림
    주문 상태가 S03으로 변경 시 호출 (추후 점주 앱 상태변경 API에서 사용)
    """
    create_notification_log(
        receiver=order.user_id,
        notification_type="N02",
        target_id=order.order_id,
        target_type="ORDER",
    )


def notify_order_cancelled(order):
    """
    N03: 주문 취소 → 소비자에게 알림
    OrderCancelView에서 S04 처리 후 호출
    """
    create_notification_log(
        receiver=order.user_id,
        notification_type="N03",
        target_id=order.order_id,
        target_type="ORDER",
    )
