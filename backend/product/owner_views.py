"""
product/owner_views.py
점주 전용 상품 관리 뷰

GET    /owner/stores/{store_id}/products/                  상품 목록 조회 (판매설정 화면)
POST   /owner/stores/{store_id}/products/                  상품 등록
PATCH  /owner/stores/{store_id}/products/{product_id}/     상품 수정
DELETE /owner/stores/{store_id}/products/{product_id}/     상품 삭제 (soft delete)
"""

import uuid
import os
import json
import urllib.request
import urllib.error

from django.conf import settings
from django.db import transaction
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework import status

from common.response import success_response, error_response, extract_first_error
from store.models.store import Store
from product.models.product import Product
from product.models.category import Category
from product.models.productImg import ProductImg
from image.models.image import Image
from product.owner_serializers import (
    OwnerProductListSerializer,
    OwnerProductCreateSerializer,
    OwnerProductUpdateSerializer,
)
from product.price_log_utils import record_price_log
# 공통 헬퍼

def check_owner_type(user):
    #점주(U02) 여부 확인
    if user.user_type != 'U02':
        return error_response("점주 전용 기능입니다.", status_code=status.HTTP_403_FORBIDDEN)
    return None


def get_owner_store(user, store_id):
    #요청 유저 소유 + 미삭제 매장 반환. 없으면 None
    try:
        return Store.objects.get(pk=store_id, user_id=user, is_deleted=False)
    except Store.DoesNotExist:
        return None


def get_owner_product(store, product_id):
    #해당 매장 소속 + 미삭제 상품 반환. 없으면 None
    try:
        return Product.objects.prefetch_related(
            'productimg_set__img_id'
        ).get(pk=product_id, store_id=store, is_deleted=False)
    except Product.DoesNotExist:
        return None


def save_product_image(image_file, user) -> Image:
    #이미지 파일을 저장하고 Image 레코드를 반환
    ext       = image_file.name.rsplit('.', 1)[-1].lower()
    uuid_name = f"{uuid.uuid4()}.{ext}"
    save_dir  = os.path.join(settings.MEDIA_ROOT, 'products')
    os.makedirs(save_dir, exist_ok=True)

    with open(os.path.join(save_dir, uuid_name), 'wb+') as f:
        for chunk in image_file.chunks():
            f.write(chunk)

    return Image.objects.create(
        user_id=user,
        img_name=image_file.name,
        img_url=f"{settings.MEDIA_URL}products/{uuid_name}",
        img_path=f"/uploads/products/{uuid_name}",
        img_uuid_name=uuid_name,
    )


ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
MAX_SIZE_BYTES = 5 * 1024 * 1024  # 5MB


def validate_image_file(image_file):
    #이미지 파일 확장자·크기 검증. 문제 있으면 에러 메시지 문자열 반환, 없으면 None
    ext = image_file.name.rsplit('.', 1)[-1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return "jpg, png, webp 형식만 업로드 가능합니다."
    if image_file.size > MAX_SIZE_BYTES:
        return "이미지 크기는 5MB 이하여야 합니다."
    return None

def _check_anomaly(store_id: int, ori_price: int, dis_price: int) -> dict | None:
    """
    ML 서버에 이상치 탐지 요청.
    - 이상치가 아니면 None 반환 (바로 저장 진행)
    - 이상치이면 ML 결과 dict 반환 (프론트에 경고 필요)
    - ML 서버 장애 시 None 반환 (저장 차단하지 않음 — 가용성 우선)
    """
    if not ori_price or ori_price <= 0:
        return None

    discount_rate = int((1 - dis_price / ori_price) * 100)

    url     = f"{settings.ML_SERVER_URL}/anomaly/detect/"
    payload = json.dumps({
        "store_id":      store_id,
        "discount_rate": discount_rate,
    }).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Content-Type":       "application/json",
            "X-Internal-API-Key": settings.ML_INTERNAL_API_KEY,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            ml   = body.get("data", {})
            if ml.get("is_anomaly"):
                return {
                    **ml,
                    "price_info": {
                        "product_ori_price": ori_price,
                        "product_dis_price": dis_price,
                        "discount_rate":     discount_rate,
                    },
                }
            return None  # 정상
    except Exception:
        return None  # ML 서버 장애 → 저장 차단하지 않음


class OwnerProductView(APIView):
    """
    GET  /owner/stores/{store_id}/products/ — 판매설정 화면 상품 목록
    POST /owner/stores/{store_id}/products/ — 상품 등록
    """
    permission_classes = [IsAuthenticated]
    parser_classes     = [MultiPartParser, FormParser, JSONParser]

    def get(self, request, store_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        products = (
            Product.objects
            .filter(store_id=store, is_deleted=False)
            .select_related('category_id')
            .prefetch_related('productimg_set__img_id')
            .order_by('reg_dt')
        )

        serializer = OwnerProductListSerializer(products, many=True)
        return success_response(data={
            'total':    products.count(),
            'products': serializer.data,
        })

    def post(self, request, store_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OwnerProductCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(extract_first_error(serializer.errors))

        data       = serializer.validated_data
        image_file = data.pop('image_file', None)

        # 이미지 검증
        if image_file:
            img_err = validate_image_file(image_file)
            if img_err:
                return error_response(img_err)

        force = str(request.data.get("force", "false")).lower() == "true"

        # ── 이상치 체크 (force=true 이면 건너뜀) ──────────────────────────────
        if not force:
            anomaly = _check_anomaly(
                store_id=store.store_id,
                ori_price=data['product_ori_price'],
                dis_price=data['product_dis_price'],
            )
            if anomaly:
                # HTTP 200 + needs_confirm=True → 프론트가 경고 다이얼로그 표시
                return success_response(
                    data={
                        "needs_confirm": True,  # ← 프론트 분기 키
                        "anomaly": anomaly,
                    },
                    message=anomaly.get("message", "할인율이 이상치로 감지되었습니다."),
                )



        with transaction.atomic():
            category = Category.objects.get(pk=data['category_id'])
            product  = Product.objects.create(
                store_id=store,
                category_id=category,
                product_name=data['product_name'],
                product_desc=data.get('product_desc'),
                product_ori_price=data['product_ori_price'],
                product_dis_price=data['product_dis_price'],
                product_count=data['product_count'],
            )

            if image_file:
                image = save_product_image(image_file, request.user)
                ProductImg.objects.create(product_id=product, img_id=image)

            record_price_log(product=product, owner=request.user)

        # 응답용 재조회
        product = Product.objects.prefetch_related(
            'productimg_set__img_id'
        ).select_related('category_id').get(pk=product.pk)

        result = OwnerProductListSerializer(product)
        return success_response(
            data={
                **result.data,
                "needs_confirm": False,  # 정상 저장 완료 명시
            },
            message="상품이 등록되었습니다.",
            status_code=status.HTTP_201_CREATED,
        )


class OwnerProductManageView(APIView):
    """
    PATCH  /owner/stores/{store_id}/products/{product_id}/ — 상품 수정
    DELETE /owner/stores/{store_id}/products/{product_id}/ — 상품 삭제 (soft delete)
    """
    permission_classes = [IsAuthenticated]
    parser_classes     = [MultiPartParser, FormParser, JSONParser]

    def patch(self, request, store_id, product_id):
        #request.user
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        product = get_owner_product(store, product_id)
        if product is None:
            return error_response("상품을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OwnerProductUpdateSerializer(data=request.data, partial=True)
        if not serializer.is_valid():
            return error_response(extract_first_error(serializer.errors))

        data       = serializer.validated_data
        image_file = data.pop('image_file', None)

        # 이미지 검증
        if image_file:
            img_err = validate_image_file(image_file)
            if img_err:
                return error_response(img_err)

        force = str(request.data.get("force", "false")).lower() == "true"

        # ── 이상치 체크: 가격이 변경되는 경우에만 수행 ──────────────────────
        new_ori = data.get('product_ori_price', product.product_ori_price)
        new_dis = data.get('product_dis_price', product.product_dis_price)
        price_changed = (
                'product_ori_price' in data or 'product_dis_price' in data
        )

        if not force and price_changed:
            anomaly = _check_anomaly(
                store_id=store.store_id,
                ori_price=new_ori,
                dis_price=new_dis,
            )
            if anomaly:
                return success_response(
                    data={
                        "needs_confirm": True,
                        "anomaly": anomaly,
                    },
                    message=anomaly.get("message", "할인율이 이상치로 감지되었습니다."),
                )

        with transaction.atomic():
            # 스칼라 필드 업데이트
            update_fields = []

            if 'product_name' in data:
                product.product_name = data['product_name']
                update_fields.append('product_name')

            if 'product_desc' in data:
                product.product_desc = data['product_desc']
                update_fields.append('product_desc')

            if 'product_ori_price' in data:
                product.product_ori_price = data['product_ori_price']
                update_fields.append('product_ori_price')

            if 'product_dis_price' in data:
                product.product_dis_price = data['product_dis_price']
                update_fields.append('product_dis_price')

            if 'product_count' in data:
                product.product_count = data['product_count']
                update_fields.append('product_count')

            if 'category_id' in data:
                product.category_id = Category.objects.get(pk=data['category_id'])
                update_fields.append('category_id')

            if update_fields:
                product.save(update_fields=update_fields)

            # 이미지 교체: 기존 ProductImg 삭제 후 새 이미지 등록
            if image_file:
                product.productimg_set.all().delete()
                image = save_product_image(image_file, request.user)
                ProductImg.objects.create(product_id=product, img_id=image)

            if price_changed:
                record_price_log(product=product, owner=request.user)


        # 응답용 재조회
        product = Product.objects.prefetch_related(
            'productimg_set__img_id'
        ).select_related('category_id').get(pk=product.pk)

        result = OwnerProductListSerializer(product)
        return success_response(data={
                **result.data,
                "needs_confirm": False,
            },
            message="상품이 수정되었습니다."
        )

    def delete(self, request, store_id, product_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        product = get_owner_product(store, product_id)
        if product is None:
            return error_response("상품을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        product.is_deleted = True
        product.save(update_fields=['is_deleted'])
        return success_response(
            data={'product_id': product_id},
            message="상품이 삭제되었습니다.",
        )

class OwnerProductSoldOutView(APIView):
    """
    PATCH /owner/stores/{store_id}/products/{product_id}/soldout/
    품절 처리 — product_count를 0으로 설정
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, store_id, product_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        product = get_owner_product(store, product_id)
        if product is None:
            return error_response("상품을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        if product.product_count == 0:
            return error_response("이미 품절 처리된 상품입니다.", status_code=status.HTTP_400_BAD_REQUEST)

        product.product_count = 0
        product.save(update_fields=['product_count'])

        return success_response(
            data={
                'product_id':    product.product_id,
                'product_name':  product.product_name,
                'product_count': 0,
                'is_available':  False,
            },
            message="품절 처리되었습니다.",
        )

