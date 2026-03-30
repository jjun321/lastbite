import math
from datetime import date
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


def get_day_code(d: date) -> str:
    return DAY_CODE_MAP[d.weekday()]


def is_off_today(store) -> bool:
    today = get_today_kst()
    return store.offdate_set.filter(off_dt=today).exists()


def get_today_open_close(store):
    #오늘 영업시작/마감 시각 반환. 없으면 (None, None)
    today = get_today_kst()
    day_code = get_day_code(today)
    wt = store.storeworkingtime_set.filter(working_day=day_code).first()
    if not wt:
        return None, None
    return wt.start_time.strftime('%H:%M'), wt.end_time.strftime('%H:%M')