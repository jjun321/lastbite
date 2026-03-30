from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.exceptions import TokenError
from django.contrib.auth import authenticate
from user.models.user import User
from .serializers import RegisterSerializer, LoginSerializer

# 응답 규격에 유저 객체 정보도 들어가기에 커스텀 뷰 구조 만듦

def api_response(success, message, data=None):
    # 응답 규격 구조체
    res = {
        "success": success,
        "message": message
    }
    if data is not None:
        res["data"] = data
    return res

class LoginView(TokenObtainPairView):
    # 로그인
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception:
            # 로그인 실패 시 명세서에 따라 AUTH_001 반환
            return Response(api_response(False, "AUTH_001"), status=status.HTTP_200_OK)

        return Response(api_response(True, "성공", serializer.validated_data), status=status.HTTP_200_OK)

class RegisterView(APIView):
    # 소비자 회원가입
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(api_response(True, "성공", {
                "user_id": user.user_id,
                "user_name": user.user_name,
                "user_email": user.user_email,
                "user_type": user.user_type
            }), status=status.HTTP_200_OK)
        
        # 에러 메시지 처리
        error_msg = "입력값을 확인해주세요."
        if serializer.errors:
            first_key = next(iter(serializer.errors))
            first_error = serializer.errors[first_key][0]
            error_msg = str(first_error)

        return Response(api_response(False, error_msg), status=status.HTTP_400_BAD_REQUEST)

class RefreshTokenView(APIView):
    # 액세스 토큰 갱신
    permission_classes = [AllowAny]

    def post(self, request):
        refresh_token = request.data.get('refresh_token')
        if not refresh_token:
             return Response(api_response(False, "Refresh token is required"), status=status.HTTP_400_BAD_REQUEST)

        try:
            refresh = RefreshToken(refresh_token)
            new_access_token = str(refresh.access_token)

            return Response(api_response(True, "성공", {
                "access_token": new_access_token
            }), status=status.HTTP_200_OK)

        except TokenError:
            return Response(api_response(False, "유효하지 않거나 만료된 토큰입니다."), status=status.HTTP_401_UNAUTHORIZED)

class LogoutView(APIView):
    # 로그아웃
    # 인증되지 않은 사용자 로그아웃 관련 처리 필요할 수도 있음. 지금은 아무나 가능
    permission_classes = [AllowAny]

    def post(self, request):
        return Response(api_response(True, "성공", {
            "result": "로그아웃 처리 완료"
        }), status=status.HTTP_200_OK)

class EmailCheckView(APIView):
    # 이메일 중복 체크
    permission_classes = [AllowAny]

    def get(self, request):
        field = request.data.get('field') or request.query_params.get('field')
        value = request.data.get('value') or request.query_params.get('value')

        if field != "email":
            return Response(api_response(False, "field는 'email'이어야 합니다."), status=status.HTTP_400_BAD_REQUEST)
        
        if not value:
            return Response(api_response(False, "이메일 값을 입력해주세요."), status=status.HTTP_400_BAD_REQUEST)

        is_exist = User.objects.filter(user_email=value).exists()
        
        return Response(api_response(True, "성공", {
            "available": not is_exist
        }), status=status.HTTP_200_OK)