"""
recommend/views.py

ML 서버 내부 엔드포인트 모음.
X-Internal-API-Key 헤더로 무단 외부 접근 차단.

엔드포인트:
  POST /recommend/              DBSCAN 군집 기반 매장 추천
  POST /anomaly/detect/         단건 이상치 탐지 (점주 사전 경고)
  POST /anomaly/detect-batch/   일괄 이상치 탐지 (소비자 특가 알림)
"""

from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from recommend.serializers import (
    RecommendRequestSerializer,
    AnomalyDetectSerializer,
    AnomalyBatchSerializer,
)
from recommend.services import get_recommendations
from recommend.services_anomaly import detect_single, detect_batch


def _check_api_key(request) -> bool:
    """헤더의 내부 API 키 검증."""
    return request.headers.get("X-Internal-API-Key", "") == settings.ML_INTERNAL_API_KEY


def _forbidden():
    return Response(
        {"success": False, "message": "인증되지 않은 요청입니다.", "data": None},
        status=status.HTTP_403_FORBIDDEN,
    )


def _bad_request(message: str):
    return Response(
        {"success": False, "message": message, "data": None},
        status=status.HTTP_400_BAD_REQUEST,
    )


# ── 추천 뷰 ──────────────────────────────────────────────────────────────────

class RecommendView(APIView):
    """POST /recommend/"""

    def post(self, request):
        if not _check_api_key(request):
            return _forbidden()

        serializer = RecommendRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return _bad_request(str(list(serializer.errors.values())[0][0]))

        results = get_recommendations(
            user_id=serializer.validated_data["user_id"],
            top_n=serializer.validated_data["top_n"],
        )

        if not results:
            return _bad_request("군집화 가능한 위치 데이터가 부족합니다. (최소 3개 이상의 위치 로그 필요)")

        return Response(
            {"success": True, "message": "성공", "data": {"total": len(results), "stores": results}},
            status=status.HTTP_200_OK,
        )


# ── 이상치 탐지 뷰 ────────────────────────────────────────────────────────────

class AnomalyDetectView(APIView):
    """
    POST /anomaly/detect/
    단건 이상치 탐지 — 점주 사전 경고

    Request Body:
        store_id      (int): 매장 PK
        discount_rate (int): 입력 예정 할인율 (%)
    """

    def post(self, request):
        if not _check_api_key(request):
            return _forbidden()

        serializer = AnomalyDetectSerializer(data=request.data)
        if not serializer.is_valid():
            return _bad_request(str(list(serializer.errors.values())[0][0]))

        result = detect_single(
            store_id=serializer.validated_data["store_id"],
            discount_rate=float(serializer.validated_data["discount_rate"]),
        )

        return Response(
            {"success": True, "message": "성공", "data": result},
            status=status.HTTP_200_OK,
        )


class AnomalyDetectBatchView(APIView):
    """
    POST /anomaly/detect-batch/
    일괄 이상치 탐지 — 소비자 특가 알림용

    Request Body:
        items: [{"store_id": int, "product_id": int, "discount_rate": int}, ...]
    """

    def post(self, request):
        if not _check_api_key(request):
            return _forbidden()

        serializer = AnomalyBatchSerializer(data=request.data)
        if not serializer.is_valid():
            return _bad_request(str(list(serializer.errors.values())[0][0]))

        anomalies = detect_batch(serializer.validated_data["items"])

        return Response(
            {
                "success": True,
                "message": "성공",
                "data": {
                    "total":     len(serializer.validated_data["items"]),
                    "anomalies": anomalies,
                },
            },
            status=status.HTTP_200_OK,
        )

