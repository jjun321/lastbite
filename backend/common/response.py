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
