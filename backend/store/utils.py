import math
from datetime import date, datetime, timedelta
import pytz
from django.utils import timezone

KST = pytz.timezone('Asia/Seoul')

# 요일 공통코드: D01=월 ~ D07=일  (Python weekday 0=월)
DAY_CODE_MAP = {i: f'D{i+1:02d}' for i in range(7)}


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    #Haversine 공식으로 두 좌표 간 거리(km) 계산
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


def get_today_kst() -> date:
    return timezone.now().astimezone(KST).date()

def get_now_kst() -> datetime:
    return timezone.now().astimezone(KST)


def get_day_code(d: date) -> str:
    return DAY_CODE_MAP[d.weekday()]


def is_off_today(store) -> bool:
    today = get_today_kst()
    return store.offdate_set.filter(off_dt=today).exists()


def get_today_open_close(store):
    """
    오늘 영업시작/마감 시각 문자열 반환.
    자정 넘는 영업(end_day_offset=1)이면 close에 '익일' prefix 붙여서 반환.
    없으면 (None, None)
    """
    today    = get_today_kst()
    day_code = get_day_code(today)
    wt       = store.storeworkingtime_set.filter(working_day=day_code).first()
    if not wt:
        return None, None

    open_str  = wt.start_time.strftime('%H:%M')
    close_str = wt.end_time.strftime('%H:%M')

    # 익일 자정 넘기는 케이스 표시 (예: "익일 01:00")
    if getattr(wt, 'end_day_offset', 0) == 1:
        close_str = f"익일 {close_str}"

    return open_str, close_str

def is_store_open_now(store) -> bool:
    if is_off_today(store):
        return False

    now      = get_now_kst()
    today    = now.date()
    day_code = get_day_code(today)
    wt       = store.storeworkingtime_set.filter(working_day=day_code).first()

    # ── 전날 야간 연장 영업 체크 (오늘 운영시간 유무와 무관하게 항상 수행) ──────
    # 예: 화요일 18:00 ~ 익일 01:00 → 수요일 00:30에도 화요일 운영 판단 필요
    yesterday     = today - timedelta(days=1)
    prev_day_code = get_day_code(yesterday)
    wt_prev       = store.storeworkingtime_set.filter(working_day=prev_day_code).first()

    if wt_prev and getattr(wt_prev, 'end_day_offset', 0) == 1:
        open_dt  = datetime.combine(yesterday, wt_prev.start_time).replace(tzinfo=KST)
        close_dt = datetime.combine(today,     wt_prev.end_time  ).replace(tzinfo=KST)
        if open_dt <= now < close_dt:
            return True   # 전날 야간 영업이 현재 시각을 포함 → 영업 중

    # ── 오늘 운영시간 기준 판단 ─────────────────────────────────────────────────
    if not wt:
        return False      # 운영시간 없음 (비정상 케이스, 현 설계에서는 미발생)

    offset     = getattr(wt, 'end_day_offset', 0)
    open_dt    = datetime.combine(today, wt.start_time).replace(tzinfo=KST)
    close_date = today + timedelta(days=offset)
    close_dt   = datetime.combine(close_date, wt.end_time).replace(tzinfo=KST)

    return open_dt <= now < close_dt



def auto_soldout_closed_stores(stores) -> int:
    """
    여러 매장을 대상으로 영업 종료된 매장의 상품을 일괄 품절(0) 처리한다.

    [자동 종료 스케줄러]
    store.tasks.auto_soldout_all_closed_stores (Celery Beat, 기본 5분 주기)에서
    전체 매장을 대상으로 호출되어, 매장마다 개별 쿼리를 날리지 않고
    "영업 종료 매장 ID 목록"을 한 번에 추려 단일 UPDATE로 처리한다.

    Args:
        stores: Store 인스턴스의 iterable (이미 메모리에 로드된 목록 권장)

    Returns:
        int: 품절 처리된 상품 row 수
    """
    from product.models.product import Product

    closed_store_ids = [s.store_id for s in stores if not is_store_open_now(s)]
    if not closed_store_ids:
        return 0

    return (
        Product.objects
        .filter(store_id__in=closed_store_ids, is_deleted=False, product_count__gt=0)
        .update(product_count=0)
    )