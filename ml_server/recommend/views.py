"""
recommend/views.py

POST /recommend/
메인 서버(backend/)에서만 호출하는 내부 엔드포인트.
X-Internal-API-Key 헤더로 무단 외부 접근 차단.
"""

from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from recommend.serializers import RecommendRequestSerializer
from recommend.services import get_recommendations


def _check_api_key(request) -> bool:
    """헤더의 내부 API 키 검증."""
    key = request.headers.get("X-Internal-API-Key", "")
    return key == settings.ML_INTERNAL_API_KEY


class RecommendView(APIView):
    """
    POST /recommend/
    Request Body: { "user_id": int, "top_n": int (optional, default 10) }
    Response:     { "success": bool, "message": str, "data": { "total": int, "stores": [...] } }
    """

    def post(self, request):
        # ── 내부 API 키 검증 ─────────────────────────────────────────────────
        if not _check_api_key(request):
            return Response(
                {"success": False, "message": "인증되지 않은 요청입니다.", "data": None},
                status=status.HTTP_403_FORBIDDEN,
            )

        # ── 요청 검증 ─────────────────────────────────────────────────────────
        serializer = RecommendRequestSerializer(data=request.data)
        if not serializer.is_valid():
            first_err = list(serializer.errors.values())[0][0]
            return Response(
                {"success": False, "message": str(first_err), "data": None},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user_id = serializer.validated_data["user_id"]
        top_n   = serializer.validated_data["top_n"]

        # ── 추천 실행 ─────────────────────────────────────────────────────────
        results = get_recommendations(user_id=user_id, top_n=top_n)

        if not results:
            return Response(
                {
                    "success": False,
                    "message": "군집화 가능한 위치 데이터가 부족합니다. (최소 3개 이상의 위치 로그 필요)",
                    "data": None,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "success": True,
                "message": "성공",
                "data": {"total": len(results), "stores": results},
            },
            status=status.HTTP_200_OK,
        )
