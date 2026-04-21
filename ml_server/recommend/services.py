"""
recommend/services.py

DBSCAN 군집화 + 가중치 스코어링 추천 로직.
Django ORM으로 DB를 직접 조회하므로 SQLAlchemy 불필요.

흐름:
  1. 유저 위치 로그 → numpy 배열 (라디안)
  2. DBSCAN 군집화 → 군집 중심(centroid) 계산
  3. centroid 기준 반경 내 매장 바운딩 박스 조회 (ORM 1차 필터)
  4. Haversine 정밀 거리 2차 필터
  5. score = ALPHA×거리점수 + BETA×조회수점수 + GAMMA×할인율점수
  6. score 내림차순 정렬 후 top_n 반환
"""

import math
from datetime import timedelta

import numpy as np
from django.conf import settings
from django.utils import timezone
from sklearn.cluster import DBSCAN

from recommend.models import LocationLog, Store, Product


# ── 설정값 로드 ───────────────────────────────────────────────────────────────
ALPHA = getattr(settings, "RECOMMEND_ALPHA", 0.5)
BETA  = getattr(settings, "RECOMMEND_BETA",  0.2)
GAMMA = getattr(settings, "RECOMMEND_GAMMA", 0.3)

DBSCAN_EPS_KM      = getattr(settings, "DBSCAN_EPS_KM",      0.5)
DBSCAN_EPS_RAD     = DBSCAN_EPS_KM / 6371.0
DBSCAN_MIN_SAMPLES = getattr(settings, "DBSCAN_MIN_SAMPLES",  3)
SEARCH_RADIUS_KM   = getattr(settings, "SEARCH_RADIUS_KM",    3.0)


# ── Haversine ─────────────────────────────────────────────────────────────────

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


# ── 위치 로그 조회 (ORM) ──────────────────────────────────────────────────────

def fetch_location_logs(user_id: int, days: int = 7) -> list[dict]:
    """최근 N일 위치 로그를 ORM으로 조회."""
    since = timezone.now() - timedelta(days=days)
    qs = (
        LocationLog.objects
        .filter(user_id=user_id, reg_dt__gte=since)
        .values("lat", "lon")
    )
    #print(LocationLog.objects.get(user_id=2))
    return list(qs)


# ── 군집 중심 계산 ────────────────────────────────────────────────────────────

def _get_centroids(coords_rad: np.ndarray, labels: np.ndarray) -> list[dict]:
    """DBSCAN 레이블 배열 → 군집 중심 좌표(도) 리스트. 군집 크기 내림차순."""
    centroids = []
    for label in set(labels) - {-1}:
        mask    = labels == label
        cluster = np.degrees(coords_rad[mask])
        centroids.append({
            "lat":   float(cluster[:, 0].mean()),
            "lon":   float(cluster[:, 1].mean()),
            "count": int(mask.sum()),
        })
    return sorted(centroids, key=lambda c: c["count"], reverse=True)


# ── 반경 내 매장 + 최고 할인율 조회 (ORM) ────────────────────────────────────

def _fetch_stores_near(clat: float, clon: float) -> list[dict]:
    """
    바운딩 박스 1차 필터(ORM) → Haversine 2차 필터.
    각 매장에 최고 할인율을 집계하여 반환.
    """
    lat_delta = SEARCH_RADIUS_KM / 111.0
    cos_lat   = math.cos(math.radians(clat)) or 1e-9
    lon_delta = SEARCH_RADIUS_KM / (111.0 * cos_lat)

    stores = (
        Store.objects
        .filter(
            is_deleted=False,
            is_closed=False,
            store_lat__gte=clat - lat_delta,
            store_lat__lte=clat + lat_delta,
            store_long__gte=clon - lon_delta,
            store_long__lte=clon + lon_delta,
        )
    )

    results = []
    for store in stores:
        if store.store_lat is None or store.store_long is None:
            continue

        dist = haversine_km(clat, clon, float(store.store_lat), float(store.store_long))
        if dist > SEARCH_RADIUS_KM:
            continue

        # 해당 매장의 최고 할인율 계산 (Python 레벨)
        products = Product.objects.filter(
            store_id=store.store_id,
            is_deleted=False,
            product_dis_price__isnull=False,
            product_ori_price__isnull=False,
        ).values("product_ori_price", "product_dis_price")

        best_rate = 0.0
        for p in products:
            ori = p["product_ori_price"] or 0
            dis = p["product_dis_price"] or 0
            if ori > 0:
                rate = (1 - dis / ori) * 100
                best_rate = max(best_rate, rate)

        results.append({
            "store_id":           store.store_id,
            "store_name":         store.store_name,
            "store_address":      store.store_address,
            "dist":               dist,
            "best_discount_rate": best_rate,
            "centroid_lat":       clat,
            "centroid_lon":       clon,
        })

    return results


# ── 메인 추천 함수 ────────────────────────────────────────────────────────────

def get_recommendations(user_id: int, top_n: int = 10) -> list[dict]:
    """
    Args:
        user_id: 추천 대상 유저 PK
        top_n:   반환할 최대 추천 매장 수

    Returns:
        score 내림차순으로 정렬된 추천 매장 리스트
    """
    # 1. 위치 로그 조회
    logs = fetch_location_logs(user_id, days=7)
    if len(logs) < DBSCAN_MIN_SAMPLES:
        return []

    # 2. DBSCAN 군집화
    coords_rad = np.radians([[l["lat"], l["lon"]] for l in logs])
    labels = DBSCAN(
        eps=DBSCAN_EPS_RAD,
        min_samples=DBSCAN_MIN_SAMPLES,
        algorithm="ball_tree",
        metric="haversine",
    ).fit(coords_rad).labels_

    centroids = _get_centroids(coords_rad, labels)
    if not centroids:
        return []

    # 3. 군집 중심별 반경 내 매장 수집 (중복 제거)
    seen_ids, candidates = set(), []
    for c in centroids:
        for store in _fetch_stores_near(c["lat"], c["lon"]):
            if store["store_id"] not in seen_ids:
                seen_ids.add(store["store_id"])
                candidates.append(store)

    if not candidates:
        return []

    # 4. 정규화용 최댓값
    max_dist = max(c["dist"] for c in candidates) or 1.0
    max_rate = max(c["best_discount_rate"] for c in candidates) or 1.0
    # view_count 컬럼 추가 전까지 BETA 항은 0으로 처리
    max_views = 1

    # 5. 스코어 계산 및 정렬
    results = []
    for c in candidates:
        dist_score = max(0.0, 1.0 - c["dist"] / max_dist)
        rate_score = c["best_discount_rate"] / max_rate
        score      = ALPHA * dist_score + BETA * 0.0 + GAMMA * rate_score

        results.append({
            "store_id":           c["store_id"],
            "store_name":         c["store_name"],
            "store_address":      c["store_address"],
            "distance_km":        round(c["dist"], 2),
            "best_discount_rate": round(c["best_discount_rate"], 1),
            "score":              round(score, 4),
            "centroid_lat":       round(c["centroid_lat"], 6),
            "centroid_lon":       round(c["centroid_lon"], 6),
        })

    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:top_n]
