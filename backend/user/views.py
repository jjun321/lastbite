import uuid, os
import urllib.request
import urllib.error
import json
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework.parsers import MultiPartParser
from user.models.user import User
from user.models.password_reset_token import PasswordResetToken
from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail
from django.db import transaction
from datetime import timedelta
from .serializers import RegisterSerializer, LoginSerializer, PasswordResetRequestSerializer, PasswordResetConfirmSerializer, UserProfileSerializer, UserProfileUpdateSerializer, PasswordChangeSerializer, LocationLogCreateSerializer, LocationLogResponseSerializer
from common.response import success_response, error_response, extract_first_error
from user.models.location_log import LocationLog
from image.models.image import Image
from notification.utils import create_default_notification_settings
from order.models.order import Order
from store.models.favorite import Favorite
from order.models.orderProdList import OrderProdList
from store.serializers import StoreListSerializer

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
            # 회원가입 완료 시 알림 수신 설정 기본값 생성 (N01~N04 전체 is_active=True)
            create_default_notification_settings(user)
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

class PasswordResetRequestView(APIView):
    #POST /auth/password/reset-request
    #이메일로 비밀번호 재설정 링크 발송
    permission_classes = [AllowAny]

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




class PasswordResetConfirmView(APIView):
    #POST /auth/password/reset-confirm
    #새 비밀번호 저장
    permission_classes = [AllowAny]

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

# -------- 마이페이지 뷰

class UserProfileView(APIView):
    #GET /users/me  — 내 프로필 조회
    #PUT /users/me  — 내 프로필 수정
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(
            api_response(True, "성공", serializer.data),
            status=status.HTTP_200_OK,
        )

    def put(self, request):
        serializer = UserProfileUpdateSerializer(
            request.user, data=request.data,
            partial=True, context={'request': request},
        )
        if not serializer.is_valid():
            return Response(
                api_response(False, extract_first_error(serializer.errors)),
                status=status.HTTP_400_BAD_REQUEST,
            )
        user = serializer.save()
        return Response(api_response(True, "성공", {
            "user_id":    user.user_id,
            "user_name":  user.user_name,
            "user_email": user.user_email,
            "user_phone": user.user_phone,
        }), status=status.HTTP_200_OK)


class PasswordChangeView(APIView):
    #PATCH /users/me/password -> 로그인 상태에서 비밀번호 변경
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        serializer = PasswordChangeSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                api_response(False, extract_first_error(serializer.errors)),
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = request.user
        current_password = serializer.validated_data['current_password']

        # 현재 비밀번호 검증
        if not user.check_password(current_password):
            return Response(
                api_response(False, "현재 비밀번호가 올바르지 않습니다."),
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(serializer.validated_data['new_password'])
        user.save(update_fields=['password'])

        return Response(api_response(True, "성공", {
            "result": "비밀번호가 변경되었습니다."
        }), status=status.HTTP_200_OK)


class ProfileImageUploadView(APIView):
    #POST /users/me/profile-image — 프로필 이미지 업로드
    permission_classes = [IsAuthenticated]
    parser_classes     = [MultiPartParser]

    # 허용 확장자 및 최대 크기
    ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
    MAX_SIZE_BYTES      = 5 * 1024 * 1024  # 5MB

    def post(self, request):
        image_file = request.FILES.get('image_file')

        if not image_file:
            return Response(
                api_response(False, "이미지 파일이 필요합니다."),
                status=status.HTTP_400_BAD_REQUEST,
            )

        ext = image_file.name.rsplit('.', 1)[-1].lower()
        if ext not in self.ALLOWED_EXTENSIONS:
            return Response(
                api_response(False, "jpg, png, webp 형식만 업로드 가능합니다."),
                status=status.HTTP_400_BAD_REQUEST,
            )

        if image_file.size > self.MAX_SIZE_BYTES:
            return Response(
                api_response(False, "이미지 크기는 5MB 이하여야 합니다."),
                status=status.HTTP_400_BAD_REQUEST,
            )

        # UUID 파일명 생성 및 저장 경로 결정
        uuid_name  = f"{uuid.uuid4()}.{ext}"
        save_dir   = os.path.join(settings.MEDIA_ROOT, 'images')
        os.makedirs(save_dir, exist_ok=True)
        save_path  = os.path.join(save_dir, uuid_name)

        with open(save_path, 'wb+') as f:
            for chunk in image_file.chunks():
                f.write(chunk)

        img_path = f"/uploads/images/{uuid_name}"
        img_url  = f"{settings.MEDIA_URL}images/{uuid_name}"

        with transaction.atomic():
            # Image 테이블에 레코드 생성
            image = Image.objects.create(
                user_id       = request.user,
                img_name      = image_file.name,
                img_url       = img_url,
                img_path      = img_path,
                img_uuid_name = uuid_name,
            )
            # 유저 프로필 이미지 갱신
            request.user.profile_img_id = image.img_id
            request.user.save(update_fields=['profile_img_id'])

        return Response(api_response(True, "성공", {
            "img_id":   image.img_id,
            "img_name": image.img_name,
            "img_url":  image.img_url,
            "img_path": image.img_path,
            "img_uuid": image.img_uuid_name,
        }), status=status.HTTP_200_OK)


class UserSavingsView(APIView):
    #GET /users/me/savings — 절약 금액 합계 조회
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # S03(처리 완료)인 주문만 집계
        completed_orders = Order.objects.filter(
            user_id=request.user,
            order_status='S03',
        )
        completed_count = completed_orders.count()

        # 완료 주문의 order_id 목록
        order_ids = completed_orders.values_list('order_id', flat=True)

        # 계산식 Σ (ori - dis) × qty 구현
        items = OrderProdList.objects.filter(order_id__in=order_ids)
        total_savings = sum(
            (item.product_ori_price - item.product_dis_price) * item.order_prod_count
            for item in items
        )

        return Response(api_response(True, "성공", {
            "total_savings":    total_savings,
            "completed_orders": completed_count,
        }), status=status.HTTP_200_OK)

class UserFavoriteListView(APIView):
    """GET /users/me/favorites — 즐겨찾기 매장 목록 조회"""
    permission_classes = [IsAuthenticated]

    def get(self, request):

        favorites = (
            Favorite.objects
            .filter(user_id=request.user, store_id__is_deleted=False)
            .select_related('store_id', 'store_id__store_img_id')
            .prefetch_related(
                'store_id__storeworkingtime_set',
                'store_id__offdate_set',
                'store_id__product_set',
            )
            .order_by('reg_dt')
        )

        stores = [fav.store_id for fav in favorites]
        serializer = StoreListSerializer(stores, many=True)
        return success_response(data={
            "total":  len(stores),
            "stores": serializer.data,
        })


class UserLocationView(APIView):
    """
    GET  /users/me/locations — 위치 로그 목록 조회
    POST /users/me/locations — 위치 저장
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        logs = LocationLog.objects.filter(user_id=request.user)
        serializer = LocationLogResponseSerializer(logs, many=True)
        return Response(
            api_response(True, "성공", serializer.data),
            status=status.HTTP_200_OK,
        )

    def post(self, request):
        serializer = LocationLogCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                api_response(False, extract_first_error(serializer.errors)),
                status=status.HTTP_400_BAD_REQUEST,
            )
        log = LocationLog.objects.create(
            user_id=request.user,
            lat=serializer.validated_data['lat'],
            lon=serializer.validated_data['lon'],
        )
        res = LocationLogResponseSerializer(log)
        return Response(
            api_response(True, "성공", res.data),
            status=status.HTTP_201_CREATED,
        )


class UserLocationDetailView(APIView):
    """
    DELETE /users/me/locations/{log_id} — 위치 삭제
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request, log_id):
        try:
            log = LocationLog.objects.get(log_id=log_id, user_id=request.user)
        except LocationLog.DoesNotExist:
            return Response(
                api_response(False, "위치 로그를 찾을 수 없습니다."),
                status=status.HTTP_404_NOT_FOUND,
            )
        log.delete()
        return Response(
            api_response(True, "성공", {"log_id": log_id}),
            status=status.HTTP_200_OK,
        )


class UserRecommendView(APIView):
    """GET /users/me/recommendations — ML 서버에 위임"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        top_n = int(request.query_params.get('top_n', 10))

        # ML 서버로 내부 HTTP 요청 (표준 라이브러리 사용, httpx 불필요)
        ml_url = f"{settings.ML_SERVER_URL}/recommend/"
        payload = json.dumps({
            "user_id": request.user.user_id,
            "top_n":   top_n,
        }).encode("utf-8")

        req = urllib.request.Request(
            ml_url,
            data=payload,
            headers={
                "Content-Type":       "application/json",
                "X-Internal-API-Key": settings.ML_INTERNAL_API_KEY,
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            body = json.loads(e.read().decode("utf-8"))
            return Response(
                api_response(False, body.get("message", "추천 결과를 가져올 수 없습니다.")),
                status=status.HTTP_400_BAD_REQUEST,
            )
        except Exception:
            return Response(
                api_response(False, "추천 서버에 연결할 수 없습니다."),
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return Response(
            api_response(True, "성공", data.get("data")),
            status=status.HTTP_200_OK,
        )