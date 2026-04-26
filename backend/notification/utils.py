"""
notification/utils.py

알림 관련 공통 헬퍼 함수 모음.
외부에서 import해서 사용하는 함수:
  - create_default_notification_settings(user)  : 회원가입 시 호출
  - ensure_notification_settings(user)          : 설정 누락 보완 (GET settings에서 호출)
  - notify_order_received(order)                : 주문 생성 시 (N01 → 점주)
  - notify_order_completed(order)               : 주문 완료 시 (N02 → 소비자)
  - notify_order_cancelled(order)               : 주문 취소 시 (N03 → 소비자)
"""
from notification.models.choices import NOTIFICATION_TYPE_CHOICE
from notification.models.notification import Notification
from notification.models.notification_log import NotificationLog


# ── 알림 설정 초기화 ──────────────────────────────────────────────────────────

def create_default_notification_settings(user):
    """
    회원가입 시 모든 알림 타입 기본 설정 행 일괄 생성 (is_active=True).
    user/views.py RegisterView에서 user.save() 직후 호출.
    """
    Notification.objects.bulk_create(
        [
            Notification(user_id=user, notification_type=code, is_active=True)
            for code, _ in NOTIFICATION_TYPE_CHOICE
        ],
        ignore_conflicts=True,
    )


def ensure_notification_settings(user):
    """
    유저의 알림 설정 행 중 누락된 타입만 추가 생성.
    구버전 가입자나 신규 타입 추가 시 안전망으로 사용.
    NotificationSettingsView.get()에서 호출.
    """
    existing = set(
        Notification.objects.filter(user_id=user)
        .values_list("notification_type", flat=True)
    )
    missing = {code for code, _ in NOTIFICATION_TYPE_CHOICE} - existing
    if missing:
        Notification.objects.bulk_create(
            [
                Notification(user_id=user, notification_type=t, is_active=True)
                for t in missing
            ],
            ignore_conflicts=True,
        )


# ── 내부 헬퍼 ─────────────────────────────────────────────────────────────────

def _get_or_create_pref(user, notification_type):
    """수신자의 알림 타입 설정 행 조회. 없으면 기본값(is_active=True)으로 생성."""
    pref, _ = Notification.objects.get_or_create(
        user_id=user,
        notification_type=notification_type,
        defaults={"is_active": True},
    )
    return pref


def _create_log(receiver, notification_type, target_id=None, target_type=None):
    """
    알림 로그 생성 내부 함수.
    수신자의 해당 타입 알림이 OFF면 생성하지 않고 None 반환.
    """
    pref = _get_or_create_pref(receiver, notification_type)
    if not pref.is_active:
        return None
    return NotificationLog.objects.create(
        notification_id=pref,
        user_id=receiver,
        target_id=target_id,
        target_type=target_type,
    )


# ── 주문 알림 퍼블릭 헬퍼 ────────────────────────────────────────────────────

def notify_order_received(order):
    """
    N01: 주문 접수 → 점주에게 알림.
    order.store_id_id 로 Store를 select_related 조회해 추가 쿼리를 최소화.
    """
    from store.models.store import Store  # 순환 import 방지를 위해 지연 import

    store = Store.objects.select_related("user_id").get(pk=order.store_id_id)
    _create_log(
        receiver=store.user_id,
        notification_type="N01",
        target_id=order.order_id,
        target_type="ORDER",
    )


def notify_order_completed(order):
    """
    N02: 주문 처리 완료 → 소비자에게 알림.
    점주 앱 주문 상태 변경(S03) API 구현 시 해당 뷰에서 호출.
    """
    _create_log(
        receiver=order.user_id,
        notification_type="N02",
        target_id=order.order_id,
        target_type="ORDER",
    )


def notify_order_cancelled(order):
    """
    N03: 주문 취소 → 소비자에게 알림.
    order/views.py OrderCancelView에서 S04 처리 완료 후 호출.
    """
    _create_log(
        receiver=order.user_id,
        notification_type="N03",
        target_id=order.order_id,
        target_type="ORDER",
    )


def notify_special_deal(user, product_id, store_id):
    """
    N05: 특가 상품 알림 → 소비자에게 알림.
    이상치 탐지에서 '너무 높은 할인(소비자 혜택)' 판정된 상품을
    주기 작업(scheduled task)에서 근처 소비자에게 발송할 때 호출.

    Args:
        user:       알림 수신 소비자 User 인스턴스
        product_id: 특가 상품 PK (target_id로 저장)
        store_id:   해당 매장 PK (메시지 구성용, 현재는 로깅만)
    """
    _create_log(
        receiver=user,
        notification_type="N05",
        target_id=product_id,
        target_type="PRODUCT",
    )
