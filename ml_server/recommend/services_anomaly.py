"""
recommend/services_anomaly.py

Isolation Forest 기반 할인율 이상치 탐지 서비스.

사용처:
  1. 점주 사전 경고 (단건 탐지): detect_single()
  2. 소비자 특가 알림 (일괄 탐지): detect_batch()

이상치 방향 판단:
  - ML 결과 -1(이상치) + discount_rate > 중앙값  → "HIGH" (너무 높은 할인)
  - ML 결과 -1(이상치) + discount_rate <= 중앙값 → "LOW"  (너무 낮은 할인)
  - ML 결과  1(정상)                             → None
"""

import numpy as np
from django.conf import settings
from sklearn.ensemble import IsolationForest

from recommend.models import PriceLog


# ── Isolation Forest 파라미터 ─────────────────────────────────────────────────
IF_CONTAMINATION  = getattr(settings, "IF_CONTAMINATION",  0.1)
IF_N_ESTIMATORS   = getattr(settings, "IF_N_ESTIMATORS",   100)
IF_RANDOM_STATE   = getattr(settings, "IF_RANDOM_STATE",   42)
IF_MIN_SAMPLES    = getattr(settings, "IF_MIN_SAMPLES",     5)   # 학습 최소 데이터 수


# ── 가격 로그 조회 ────────────────────────────────────────────────────────────

def _fetch_discount_rates(store_id: int) -> list[float]:
    """
    해당 매장의 가격 로그에서 discount_rate 목록 조회.
    null 제거 후 float 리스트 반환.
    """
    qs = (
        PriceLog.objects
        .filter(store_id=store_id, discount_rate__isnull=False)
        .values_list("discount_rate", flat=True)
    )
    return [float(r) for r in qs]


def _build_model(rates: list[float]) -> tuple[IsolationForest, float, float]:
    """
    discount_rate 리스트로 Isolation Forest 학습.
    Returns:
        model:  학습된 IsolationForest
        mean:   데이터셋 평균
        median: 데이터셋 중앙값
    """
    X      = np.array(rates).reshape(-1, 1)
    mean   = float(np.mean(X))
    median = float(np.median(X))
    model  = IsolationForest(
        contamination=IF_CONTAMINATION,
        n_estimators=IF_N_ESTIMATORS,
        random_state=IF_RANDOM_STATE,
    )
    model.fit(X)
    return model, mean, median


def _classify(prediction: int, discount_rate: float, median: float) -> str | None:
    """
    Isolation Forest 예측값과 중앙값으로 이상치 방향 결정.
    Returns: "HIGH" | "LOW" | None
    """
    if prediction == 1:
        return None
    return "HIGH" if discount_rate > median else "LOW"


def _build_message(direction: str | None, discount_rate: float) -> str:
    if direction is None:
        return "정상 범위의 할인율입니다."
    if direction == "HIGH":
        return (
            f"입력하신 할인율({discount_rate}%)은 기존 데이터 대비 지나치게 높습니다. "
            "이대로 등록하시겠습니까?"
        )
    return (
        f"입력하신 할인율({discount_rate}%)은 기존 데이터 대비 지나치게 낮습니다. "
        "이대로 등록하시겠습니까?"
    )


# ── 퍼블릭 API ────────────────────────────────────────────────────────────────

def detect_single(store_id: int, discount_rate: float) -> dict:
    """
    점주 사전 경고용 단건 탐지.

    Args:
        store_id:      매장 PK
        discount_rate: 점주가 입력한 할인율 (%)

    Returns:
        {
            "is_anomaly":    bool,
            "direction":     "HIGH" | "LOW" | null,
            "discount_rate": float,
            "message":       str,
            "dataset_mean":  float | null,
            "dataset_median":float | null,
        }
    """
    rates = _fetch_discount_rates(store_id)

    # 학습 데이터 부족 시 탐지 불가 → 정상으로 처리하되 플래그 추가
    if len(rates) < IF_MIN_SAMPLES:
        return {
            "is_anomaly":     False,
            "direction":      None,
            "discount_rate":  discount_rate,
            "message":        f"학습 데이터가 부족합니다. (현재 {len(rates)}건, 최소 {IF_MIN_SAMPLES}건 필요)",
            "dataset_mean":   None,
            "dataset_median": None,
        }

    model, mean, median = _build_model(rates)
    prediction           = int(model.predict([[discount_rate]])[0])
    direction            = _classify(prediction, discount_rate, median)

    return {
        "is_anomaly":     direction is not None,
        "direction":      direction,
        "discount_rate":  discount_rate,
        "message":        _build_message(direction, discount_rate),
        "dataset_mean":   round(mean, 2),
        "dataset_median": round(median, 2),
    }


def detect_batch(items: list[dict]) -> list[dict]:
    """
    소비자 특가 알림용 일괄 탐지.
    store_id별로 모델을 따로 학습하여 해당 매장 기준으로 이상치 판정.

    Args:
        items: [{"store_id": int, "product_id": int, "discount_rate": int}, ...]

    Returns:
        이상치인 항목만 필터링한 리스트:
        [{"store_id", "product_id", "discount_rate", "direction", "message"}, ...]
    """
    # store_id별로 그룹핑
    from collections import defaultdict
    groups: dict[int, list[dict]] = defaultdict(list)
    for item in items:
        groups[item["store_id"]].append(item)

    anomalies = []
    for store_id, group_items in groups.items():
        rates = _fetch_discount_rates(store_id)
        if len(rates) < IF_MIN_SAMPLES:
            continue  # 데이터 부족 매장은 건너뜀

        model, _, median = _build_model(rates)

        for item in group_items:
            dr         = float(item["discount_rate"])
            prediction = int(model.predict([[dr]])[0])
            direction  = _classify(prediction, dr, median)

            if direction is not None:
                anomalies.append({
                    "store_id":      item["store_id"],
                    "product_id":    item["product_id"],
                    "discount_rate": dr,
                    "direction":     direction,
                    "message":       _build_message(direction, dr),
                })

    return anomalies
