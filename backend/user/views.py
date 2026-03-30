from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.exceptions import TokenError
from django.contrib.auth import authenticate
from user.models.user import User
from user.models.password_reset_token import PasswordResetToken
from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail
from datetime import timedelta
from .serializers import RegisterSerializer, LoginSerializer, PasswordResetRequestSerializer, PasswordResetConfirmSerializer

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
    permission_classes = [IsAuthenticated]
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
    permission_classes = [IsAuthenticated]

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
    permission_classes = [IsAuthenticated]

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
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response(api_response(True, "성공", {
            "result": "로그아웃 처리 완료"
        }), status=status.HTTP_200_OK)

class EmailCheckView(APIView):
    # 이메일 중복 체크
    permission_classes = [IsAuthenticated]

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

class PasswordResetRequestView(APIView):
    #POST /auth/password/reset-request
    #이메일로 비밀번호 재설정 링크 발송
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                api_response(False, "입력값을 확인해주세요."),
                status=status.HTTP_400_BAD_REQUEST
            )

        email = serializer.validated_data['user_email']

        # 재설정 계속하는 것으로 이메일 계정이 존재하는 지 안 하는지 확인 하는 것 막기 위해 미존재 시에도 성공 응답 반환
        try:
            user = User.objects.get(user_email=email, is_active=True)
        except User.DoesNotExist:
            return Response(api_response(True, "성공"), status=status.HTTP_200_OK)


        PasswordResetToken.objects.filter(
            user_id=user, is_used=False
        ).update(is_used=True)
        
        expired_at = timezone.now() + timedelta(
            minutes=getattr(settings, 'PASSWORD_RESET_TIMEOUT_MINUTES', 30)
        )
        reset_token = PasswordResetToken.objects.create(
            user_id=user,
            expired_at=expired_at,
        )

        # 재설정 링크 구성 및 메일 발송
        reset_url = f"{settings.FRONTEND_RESET_URL}?token={reset_token.token}"
        send_mail(
            subject="[LastBite] 비밀번호 재설정 안내",
            message=(
                f"안녕하세요, {user.user_name}님.\n\n"
                f"아래 링크를 클릭하여 비밀번호를 재설정하세요.\n"
                f"링크는 {settings.PASSWORD_RESET_TIMEOUT_MINUTES}분 후 만료됩니다.\n\n"
                f"{reset_url}\n\n"
                f"본인이 요청하지 않았다면 이 메일을 무시하세요."
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response(api_response(True, "성공"), status=status.HTTP_200_OK)


class PasswordResetConfirmCheckView(APIView):
    #GET /auth/password/reset-confirm?token=<uuid>
    #토큰 유효성 검증 (프론트에서 링크 접근 시 호출)
    permission_classes = [IsAuthenticated]

    def get(self, request):
        token_value = request.query_params.get('token')
        if not token_value:
            return Response(
                api_response(False, "토큰이 필요합니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            reset_token = PasswordResetToken.objects.get(token=token_value)
        except (PasswordResetToken.DoesNotExist, ValueError):
            return Response(
                api_response(False, "유효하지 않은 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        if reset_token.is_used:
            return Response(
                api_response(False, "이미 사용된 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        if timezone.now() > reset_token.expired_at:
            return Response(
                api_response(False, "만료된 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response(api_response(True, "성공", {"valid": True}), status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    #POST /auth/password/reset-confirm
    #새 비밀번호 저장
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if not serializer.is_valid():
            first_key = next(iter(serializer.errors))
            first_error = serializer.errors[first_key][0]
            return Response(
                api_response(False, str(first_error)),
                status=status.HTTP_400_BAD_REQUEST
            )

        token_value = serializer.validated_data['token']
        new_password = serializer.validated_data['user_password']

        try:
            reset_token = PasswordResetToken.objects.select_related('user_id').get(
                token=token_value
            )
        except PasswordResetToken.DoesNotExist:
            return Response(
                api_response(False, "유효하지 않은 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        if reset_token.is_used:
            return Response(
                api_response(False, "이미 사용된 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        if timezone.now() > reset_token.expired_at:
            return Response(
                api_response(False, "만료된 토큰입니다."),
                status=status.HTTP_400_BAD_REQUEST
            )

        # 비밀번호 변경 및 토큰 소진
        user = reset_token.user_id
        user.set_password(new_password)
        user.save(update_fields=['password'])

        reset_token.is_used = True
        reset_token.save(update_fields=['is_used'])

        return Response(api_response(True, "성공", {
            "result": "비밀번호가 성공적으로 변경되었습니다."
        }), status=status.HTTP_200_OK)