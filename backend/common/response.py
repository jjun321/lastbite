from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


def success_response(data=None, message="성공", status_code=status.HTTP_200_OK):
    """통일된 성공 응답"""
    return Response(
        {"success": True, "message": message, "data": data},
        status=status_code,
    )


def error_response(message="오류가 발생했습니다.", code=None, status_code=status.HTTP_400_BAD_REQUEST):
    """통일된 에러 응답"""
    body = {"success": False, "message": message, "data": None}
    if code:
        body["code"] = code
    return Response(body, status=status_code)


def extract_first_error(errors):
    """
    Serializer errors에서 첫 번째 에러 메시지 추출
    order/views.py, cart/views.py 등에서 공통으로 사용
    """
    if not errors:
        return "오류가 발생했습니다."
    first_val = list(errors.values())[0]
    if isinstance(first_val, list):
        return str(first_val[0])
    if isinstance(first_val, dict):
        return str(list(first_val.values())[0][0])
    return str(first_val)


def custom_exception_handler(exc, context):
    """DRF 전역 예외 핸들러 - 모든 에러를 통일 포맷으로 반환"""
    response = exception_handler(exc, context)
    if response is not None:
        if isinstance(response.data, dict):
            message = str(response.data.get("detail", "오류가 발생했습니다."))
        elif isinstance(response.data, list):
            message = str(response.data[0])
        else:
            message = str(response.data)
        response.data = {"success": False, "message": message, "data": None}
    return response
