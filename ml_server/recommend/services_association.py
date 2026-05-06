"""
recommend/services_association.py

연관 규칙 기반 매장 추천 서비스.

역할 1 — DBSCAN 결과 boost:
  군집 추천 매장 중 "유저가 과거에 구매한 카테고리"와 카테고리가 겹치는 매장의 score를 상향.

역할 2 — Cold Start 폴백:
  위치 로그 부족으로 DBSCAN 실패 시,
  유저 주문 이력의 카테고리 → 연관 카테고리를 FP-Growth로 찾아 해당 카테고리 매장 반환.

역할 3 — 완전 Cold Start 폴백:
  주문 이력도 없을 때, 전체 S03 완료 주문 수 + 즐겨찾기 수 기준 인기 매장 반환.

연관 규칙 알고리즘:
  mlxtend의 FP-Growth 사용 (Apriori보다 메모리 효율적).
  트랜잭션 단위 = order_id (장바구니가 매장 단위로 분리되어 있으므로
  카테고리 수준 연관 규칙은 사용자 전체 주문 이력을 하나의 바스켓으로 봄).
"""

from collections import defaultdict, Counter

from django.conf import settings
from mlxtend.frequent_patterns import fpgrowth, association_rules
from mlxtend.preprocessing import TransactionEncoder
import pandas as pd

from recommend.models import Order, OrderItem, ProductCategory, Store, Favorite

# ── 파라미터 ──────────────────────────────────────────────────────────────────
MIN_SUPPORT    = getattr(settings, "AR_MIN_SUPPORT",    0.05)  # 빈도 최소 지지도
MIN_CONFIDENCE = getattr(settings, "AR_MIN_CONFIDENCE", 0.3)   # 연관 최소 신뢰도
BOOST_WEIGHT   = getattr(settings, "AR_BOOST_WEIGHT",   0.15)  # 연관 매장 score boost 량
POPULARITY_TOP = getattr(settings, "AR_POPULARITY_TOP", 10)    # 인기도 폴백 반환 수


# ── 공통 헬퍼 ─────────────────────────────────────────────────────────────────

def _get_user_category_history(user_id: int) -> list[int]:
    """
    유저의 S03(완료) 주문 이력에서 구매한 category_id 목록 반환.
    중복 포함 — 자주 산 카테고리가 여러 번 등장.
    """
    completed_order_ids = list(
        Order.objects
        .filter(user_id=user_id, order_status="S03")
        .values_list("order_id", flat=True)
    )
    if not completed_order_ids:
        return []

    product_ids = list(
        OrderItem.objects
        .filter(order_id__in=completed_order_ids)
        .values_list("product_id", flat=True)
    )
    if not product_ids:
        return []

    category_ids = list(
        ProductCategory.objects
        .filter(product_id__in=product_ids, is_deleted=False)
        .values_list("category_id", flat=True)
    )
    return category_ids


def _get_stores_by_categories(category_ids: list[int]) -> list[int]:
    """카테고리 ID 목록 → 해당 카테고리 상품을 보유한 미삭제·미마감 매장 ID 목록."""
    if not category_ids:
        return []
    store_ids = list(
        ProductCategory.objects
        .filter(category_id__in=category_ids, is_deleted=False)
        .values_list("store_id", flat=True)
        .distinct()
    )
    # 미마감 매장만 필터
    active_store_ids = list(
        Store.objects
        .filter(store_id__in=store_ids, is_deleted=False, is_closed=False)
        .values_list("store_id", flat=True)
    )
    return active_store_ids


# ── 역할 1: DBSCAN 결과에 boost 적용 ─────────────────────────────────────────

def boost_by_association(
    user_id: int,
    candidates: list[dict],
) -> list[dict]:
    """
    DBSCAN 추천 결과(candidates)에서
    유저가 과거에 산 카테고리와 겹치는 매장의 score를 BOOST_WEIGHT만큼 올림.

    Args:
        user_id:    추천 대상 유저 PK
        candidates: services.py의 candidates 리스트
                    각 항목: {"store_id", "score", ...}

    Returns:
        score가 조정된 candidates (정렬은 services.py에서 수행)
    """
    user_categories = set(_get_user_category_history(user_id))
    if not user_categories:
        return candidates  # 이력 없으면 boost 없이 그대로 반환

    boosted_store_ids = set(_get_stores_by_categories(list(user_categories)))

    for c in candidates:
        if c["store_id"] in boosted_store_ids:
            c["score"] = round(min(1.0, c["score"] + BOOST_WEIGHT), 4)
            c["boosted"] = True  # 프론트 디버깅용 플래그
        else:
            c["boosted"] = False

    return candidates


# ── 역할 2: 연관 규칙 Cold Start 폴백 ────────────────────────────────────────

def _build_transaction_dataset() -> list[list[str]]:
    """
    전체 S03 완료 주문에서 FP-Growth용 트랜잭션 데이터셋 구성.

    트랜잭션 단위 = user_id (사용자 전체 구매 이력을 하나의 바스켓으로).
    이유: order_id 단위(매장 단위)로 보면 항목이 1~3개로 너무 적어
          충분한 연관 규칙이 도출되지 않음.

    반환: [["cat_1", "cat_3"], ["cat_2", "cat_1", "cat_5"], ...]
    """
    completed_orders = Order.objects.filter(order_status="S03").values("order_id", "user_id")

    # user_id → order_id 목록
    user_orders: dict[int, list[int]] = defaultdict(list)
    for row in completed_orders:
        user_orders[row["user_id"]].append(row["order_id"])

    # order_id → product_id 목록
    all_order_ids = [oid for oids in user_orders.values() for oid in oids]
    order_products: dict[int, list[int]] = defaultdict(list)
    for row in OrderItem.objects.filter(order_id__in=all_order_ids).values("order_id", "product_id"):
        order_products[row["order_id"]].append(row["product_id"])

    # product_id → category_id
    all_product_ids = [pid for pids in order_products.values() for pid in pids]
    prod_category: dict[int, int] = {}
    for row in ProductCategory.objects.filter(
        product_id__in=all_product_ids, is_deleted=False
    ).values("product_id", "category_id"):
        prod_category[row["product_id"]] = row["category_id"]

    # 유저별 카테고리 바스켓 구성
    transactions = []
    for user_id, order_ids in user_orders.items():
        basket = set()
        for oid in order_ids:
            for pid in order_products.get(oid, []):
                cat = prod_category.get(pid)
                if cat:
                    basket.add(f"cat_{cat}")
        if len(basket) >= 2:  # 연관 규칙이 의미 있으려면 2개 이상 카테고리 필요
            transactions.append(list(basket))

    return transactions


def _run_fpgrowth(transactions: list[list[str]]) -> pd.DataFrame | None:
    """
    FP-Growth로 연관 규칙 추출.
    데이터 부족 시 None 반환.
    """
    if len(transactions) < 10:  # 최소 10명의 사용자 이력 필요
        return None

    te = TransactionEncoder()
    te_array = te.fit_transform(transactions)
    df = pd.DataFrame(te_array, columns=te.columns_)

    frequent_itemsets = fpgrowth(df, min_support=MIN_SUPPORT, use_colnames=True)
    if frequent_itemsets.empty:
        return None

    rules = association_rules(frequent_itemsets, metric="confidence", min_threshold=MIN_CONFIDENCE)
    return rules if not rules.empty else None


def recommend_by_association(user_id: int, top_n: int = 10) -> list[dict]:
    """
    연관 규칙 기반 Cold Start 폴백 추천.

    흐름:
      1. 유저의 구매 카테고리 이력 조회
      2. 전체 사용자 트랜잭션으로 FP-Growth 연관 규칙 추출
      3. 유저 카테고리 → 연관 카테고리 도출
      4. 연관 카테고리 보유 매장 반환

    Returns:
        [{"store_id", "store_name", "store_address", "score", "reason"}, ...]
    """
    # 1. 유저 카테고리 이력
    user_categories = _get_user_category_history(user_id)
    if not user_categories:
        return []  # 이력 없으면 인기도 폴백으로 넘어감

    user_cat_set = {f"cat_{c}" for c in set(user_categories)}

    # 2. FP-Growth 연관 규칙
    transactions = _build_transaction_dataset()
    rules = _run_fpgrowth(transactions)

    if rules is None:
        # 연관 규칙 도출 실패 → 유저 카테고리 직접 활용
        target_categories = list(set(user_categories))
    else:
        # 3. 유저 카테고리가 antecedent에 포함된 규칙 필터
        matched_rules = rules[
            rules["antecedents"].apply(lambda a: bool(a & user_cat_set))
        ].sort_values("confidence", ascending=False)

        if matched_rules.empty:
            target_categories = list(set(user_categories))
        else:
            # consequent에서 추천 카테고리 추출 (user가 이미 산 카테고리 제외)
            recommended_cats = set()
            for _, row in matched_rules.iterrows():
                recommended_cats |= row["consequents"]
            recommended_cats -= user_cat_set  # 이미 산 카테고리 제외

            target_categories = [int(c.replace("cat_", "")) for c in recommended_cats]
            if not target_categories:
                target_categories = list(set(user_categories))  # fallback

    # 4. 연관 카테고리 → 매장 조회
    store_ids = _get_stores_by_categories(target_categories)
    if not store_ids:
        return []

    stores = Store.objects.filter(
        store_id__in=store_ids,
        is_deleted=False,
        is_closed=False,
    )[:top_n]

    results = []
    for store in stores:
        results.append({
            "store_id":     store.store_id,
            "store_name":   store.store_name,
            "store_address": store.store_address,
            "distance_km":  None,  # Cold Start — 위치 정보 없음
            "best_discount_rate": 0.0,
            "score":        round(MIN_CONFIDENCE, 4),  # 연관 신뢰도를 score 대리값으로 사용
            "centroid_lat": None,
            "centroid_lon": None,
            "reason":       "association_rule",  # 추천 근거 명시
        })

    return results


# ── 역할 3: 완전 Cold Start — 인기도 폴백 ────────────────────────────────────

def recommend_by_popularity(top_n: int = 10) -> list[dict]:
    """
    주문 수 + 즐겨찾기 수 기준 인기 매장 반환.
    어떤 이력도 없는 완전 신규 사용자에게 사용.

    인기 점수 = 완료 주문 수(S03) × 0.7 + 즐겨찾기 수 × 0.3
    """
    # 완료 주문 수 집계
    order_counts: Counter = Counter(
        Order.objects
        .filter(order_status="S03")
        .values_list("store_id", flat=True)
    )

    # 즐겨찾기 수 집계
    fav_counts: Counter = Counter(
        Favorite.objects.values_list("store_id", flat=True)
    )

    # 점수 계산 대상 매장
    all_store_ids = set(order_counts.keys()) | set(fav_counts.keys())
    if not all_store_ids:
        return []

    # 정규화용 최댓값
    max_orders = max(order_counts.values(), default=1)
    max_favs   = max(fav_counts.values(),   default=1)

    scored = []
    for sid in all_store_ids:
        order_score = (order_counts.get(sid, 0) / max_orders) * 0.7
        fav_score   = (fav_counts.get(sid, 0)   / max_favs)   * 0.3
        scored.append((sid, round(order_score + fav_score, 4)))

    scored.sort(key=lambda x: x[1], reverse=True)
    top_store_ids = [sid for sid, _ in scored[:top_n]]
    score_map     = {sid: sc for sid, sc in scored}

    stores = {
        s.store_id: s
        for s in Store.objects.filter(
            store_id__in=top_store_ids,
            is_deleted=False,
            is_closed=False,
        )
    }

    results = []
    for sid in top_store_ids:
        if sid not in stores:
            continue
        store = stores[sid]
        results.append({
            "store_id":           store.store_id,
            "store_name":         store.store_name,
            "store_address":      store.store_address,
            "distance_km":        None,
            "best_discount_rate": 0.0,
            "score":              score_map[sid],
            "centroid_lat":       None,
            "centroid_lon":       None,
            "reason":             "popularity",
        })

    return results