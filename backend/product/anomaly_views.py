"""
product/anomaly_views.py

이상치 탐지 관련 뷰 — ML 서버에 위임하는 방식

1. POST /anomaly/check/
   점주가 제품 등록/수정 전 할인율 이상치 여부를 사전 확인.
   요청 → ML 서버 → 결과 반환 (점주 경고용)

2. POST /anomaly/notify-special-deals/
   주기적으로 호출되는 내부 엔드포인트 (스케줄러 또는 관리자 호출).
   근처 모든 매장의 대표 상품(rep_product) 할인율을 ML 서버로 보내
   '너무 높은 할인(소비자 혜택)' 판정된 상품 → 소비자 특가 알림(N05) 발송.
"""

import json
import urllib.request
import urllib.error

from django.conf import settings
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import status

from common.response import success_response, error_response
from product.models.product import Product
from store.models.store import Store
from notification.utils import notify_special_deal
from user.models.user import User


# ── ML 서버 내부 호출 헬퍼 ───────────────────────────────────────────────────

def _call_ml(endpoint: str, payload: dict) -> dict:
    """
    ML 서버의 엔드포인트를 동기 HTTP POST로 호출.
    성공 시 응답 JSON dict 반환.
    실패 시 ConnectionError 또는 ValueError 발생.
    """
    url  = f"{settings.ML_SERVER_URL}/{endpoint}/"
    data = json.dumps(payload).encode("utf-8")
    req  = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type":       "application/json",
            "X-Internal-API-Key": settings.ML_INTERNAL_API_KEY,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = json.loads(e.read().decode("utf-8"))
        raise ValueError(body.get("message", "ML 서버 오류"))
    except Exception as exc:
        raise ConnectionError(str(exc))


# ── 뷰 1: 점주 사전 경고 ─────────────────────────────────────────────────────

class AnomalyCheckView(APIView):
    """
    POST /anomaly/check/

    점주가 제품 등록/수정 화면에서 가격 입력 후 저장 전 호출.
    할인율이 이상치인지 확인하고, 이상치이면 방향(HIGH/LOW)과 함께 반환.

    Request Body:
        store_id         (int, required) : 해당 매장 PK
        discount_rate    (int, required) : 입력 예정 할인율 (%)
        product_dis_price (int, required): 입력 예정 할인가
        product_ori_price (int, required): 입력 예정 정가

    Response data:
        is_anomaly       (bool)  : 이상치 여부
        direction        (str)   : "HIGH" | "LOW" | null
        discount_rate    (int)   : 입력된 할인율
        message          (str)   : 사용자 표시 경고 메시지
        dataset_mean     (float) : 매장 내 기존 할인율 평균
        dataset_median   (float) : 매장 내 기존 할인율 중앙값
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        store_id      = request.data.get("store_id")
        discount_rate = request.data.get("discount_rate")
        dis_price     = request.data.get("product_dis_price")
        ori_price     = request.data.get("product_ori_price")

        # 필수값 검증
        if None in (store_id, dis_price, ori_price):
            return error_response("store_id, product_dis_price, product_ori_price는 필수입니다.")

        # discount_rate가 없으면 직접 계산
        if discount_rate is None:
            if ori_price and ori_price > 0:
                discount_rate = int((1 - dis_price / ori_price) * 100)
            else:
                return error_response("정가(product_ori_price)는 0보다 커야 합니다.")

        if dis_price > ori_price:
            return error_response("할인가는 정가보다 클 수 없습니다.")

        # ML 서버 호출
        try:
            result = _call_ml("anomaly/detect", {
                "store_id":      store_id,
                "discount_rate": discount_rate,
            })
        except ValueError as e:
            return error_response(str(e))
        except ConnectionError:
            return error_response(
                "이상치 탐지 서버에 연결할 수 없습니다.",
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        ml_data = result.get("data", {})
        response_data = {
            **ml_data,  # is_anomaly, direction, message, dataset_mean, dataset_median
            "price_info": {  # ← 추가 블록
                "product_ori_price": ori_price,
                "product_dis_price": dis_price,
                "discount_rate": discount_rate,
            },
        }
        return success_response(data=response_data)


# ── 뷰 2: 소비자 특가 알림 발송 (스케줄러/관리자 호출) ───────────────────────

class AnomalyNotifySpecialDealsView(APIView):
    """
    POST /anomaly/notify-special-deals/

    주기적으로 실행 (예: Django-Q 스케줄러, cron 등).
    전체 활성 매장의 대표 상품(rep_product) 할인율을 ML 서버로 보내
    '너무 높은 할인(HIGH)' 판정된 상품의 소비자에게 N05 알림 발송.

    Request Body:
        lat    (float, optional): 기준 위도  (없으면 전체 매장 대상)
        lon    (float, optional): 기준 경도
        radius (float, optional): 탐색 반경 km (기본 3)

    내부 API 키로만 접근 가능. 외부 클라이언트 직접 호출 불가.
    """
    permission_classes = [AllowAny]

    def _check_api_key(self, request) -> bool:
        return request.headers.get("X-Internal-API-Key", "") == settings.ML_INTERNAL_API_KEY

    def post(self, request):
        if not self._check_api_key(request):
            return error_response("인증되지 않은 요청입니다.", status_code=status.HTTP_403_FORBIDDEN)

        # 활성 매장 조회
        stores = Store.objects.filter(is_deleted=False, is_closed=False).prefetch_related(
            "product_set"
        )
        # 각 매장의 대표 상품(할인가 최저) 할인율 수집
        store_products = []
        for store in stores:
            rep = (
                store.product_set
                .filter(is_deleted=False, product_dis_price__isnull=False, product_ori_price__isnull=False)
                .order_by("product_dis_price")
                .first()
            )
            if not rep or not rep.product_ori_price:
                continue
            rate = int((1 - rep.product_dis_price / rep.product_ori_price) * 100)
            store_products.append({
                "store_id":    store.store_id,
                "product_id":  rep.product_id,
                "discount_rate": rate,
            })

        if not store_products:
            return success_response(data={"notified": 0}, message="알림 대상 상품이 없습니다.")

        # ML 서버에 일괄 이상치 탐지 요청
        try:
            result = _call_ml("anomaly/detect-batch", {
                "items": store_products,
            })
        except (ValueError, ConnectionError) as e:
            return error_response(str(e), status_code=status.HTTP_503_SERVICE_UNAVAILABLE)

        # HIGH(너무 높은 할인) 판정된 상품만 소비자에게 알림
        anomalies = result.get("data", {}).get("anomalies", [])
        high_items = [a for a in anomalies if a.get("direction") == "HIGH"]

        notified_count = 0
        consumers = User.objects.filter(user_type="U01", is_active=True)

        for item in high_items:
            product_id = item["product_id"]
            store_id   = item["store_id"]
            for consumer in consumers:
                try:
                    notify_special_deal(
                        user=consumer,
                        product_id=product_id,
                        store_id=store_id,
                    )
                    notified_count += 1
                except Exception:
                    continue

        return success_response(data={
            "total_checked": len(store_products),
            "anomalies_found": len(high_items),
            "notified": notified_count,
        })
