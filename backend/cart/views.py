import json
import uuid

import redis
from django.conf import settings
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from cart.serializers import CartItemAddSerializer, CartItemUpdateSerializer
from common.response import error_response, extract_first_error, success_response
from product.models.product import Product

CART_TTL = 60 * 60 * 24 * 7  # 7일


def get_redis():
    """Redis 클라이언트 반환"""
    return redis.from_url(
        settings.REDIS_URL,
        decode_responses=True,
    )


def get_cart_key(user_id):
    """Redis 키 생성"""
    return f"cart:{user_id}"


def get_cart_data(r, user_id):
    """Redis에서 장바구니 데이터 조회"""
    key = get_cart_key(user_id)
    data = r.get(key)
    if data:
        return json.loads(data)
    return None


def save_cart_data(r, user_id, cart_data):
    """Redis에 장바구니 데이터 저장"""
    key = get_cart_key(user_id)
    r.setex(key, CART_TTL, json.dumps(cart_data))


def calc_totals(items):
    """total_quantity, total_price 계산"""
    total_quantity = sum(item['quantity'] for item in items)
    total_price = sum(item['subtotal'] for item in items)
    return total_quantity, total_price


def get_cart_item_or_404(cart, cart_item_id):
    """
    장바구니 항목 조회 헬퍼 함수
    CartItemDetailView의 patch, delete 양쪽에서 동일한 조회 로직이
    중복되어 함수로 분리
    조회 성공 시 item 반환, 실패 시 None 반환
    """
    if not cart:
        return None
    return next(
        (i for i in cart['items'] if i['cart_item_id'] == cart_item_id),
        None
    )


class CartView(APIView):
    """
    GET    /cart/  - 장바구니 조회
    DELETE /cart/  - 장바구니 전체 비우기
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        r = get_redis()
        cart = get_cart_data(r, request.user.pk)

        if not cart:
            return success_response(data=None)

        total_quantity, total_price = calc_totals(cart['items'])

        return success_response(
            data={
                "store_id": cart['store_id'],
                "store_name": cart['store_name'],
                "items": cart['items'],
                "total_quantity": total_quantity,
                "total_price": total_price,
            }
        )

    def delete(self, request):
        r = get_redis()
        key = get_cart_key(request.user.pk)
        r.delete(key)
        return success_response(data=None, message="장바구니가 비워졌습니다.")


class CartItemView(APIView):
    """
    POST /cart/items/ - 장바구니 상품 추가
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CartItemAddSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(message=extract_first_error(serializer.errors))

        product_id = serializer.validated_data['product_id']
        quantity = serializer.validated_data['quantity']

        # 상품 존재 여부 확인
        try:
            product = Product.objects.get(product_id=product_id, is_deleted=False)
        except Product.DoesNotExist:
            return error_response(
                message="존재하지 않는 상품입니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # 재고 확인
        if product.product_count is None or product.product_count < quantity:
            return error_response(message="재고가 부족합니다.")

        r = get_redis()
        cart = get_cart_data(r, request.user.pk)

        # 다른 매장 상품 담기 방지
        if cart and cart['store_id'] != product.store_id_id:
            return error_response(
                message="다른 매장의 상품은 함께 담을 수 없습니다. 장바구니를 먼저 비워주세요."
            )

        # 장바구니 없으면 새로 생성
        if not cart:
            cart = {
                "store_id": product.store_id_id,
                "store_name": product.store_id.store_name,
                "items": []
            }

        # 이미 담긴 상품이면 수량 누적
        existing = next(
            (item for item in cart['items'] if item['product_id'] == product_id),
            None
        )

        if existing:
            existing['quantity'] += quantity
            existing['subtotal'] = product.product_dis_price * existing['quantity']
            cart_item_id = existing['cart_item_id']
        else:
            cart_item_id = str(uuid.uuid4())
            cart['items'].append({
                "cart_item_id": cart_item_id,
                "product_id": product_id,
                "product_name": product.product_name,
                "product_dis_price": product.product_dis_price,
                "quantity": quantity,
                "product_qty": product.product_count,
                "subtotal": product.product_dis_price * quantity,
            })

        save_cart_data(r, request.user.pk, cart)

        return success_response(
            data={"cart_item_id": cart_item_id},
            status_code=status.HTTP_201_CREATED,
        )


class CartItemDetailView(APIView):
    """
    PATCH  /cart/items/{cart_item_id}/ - 수량 변경
    DELETE /cart/items/{cart_item_id}/ - 상품 개별 삭제
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, cart_item_id):
        serializer = CartItemUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(message=extract_first_error(serializer.errors))

        r = get_redis()
        cart = get_cart_data(r, request.user.pk)
        item = get_cart_item_or_404(cart, cart_item_id)

        if not cart:
            return error_response(
                message="장바구니가 비어 있습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        if not item:
            return error_response(
                message="장바구니 항목을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # 재고 확인
        quantity = serializer.validated_data['quantity']
        if item['product_qty'] is not None and item['product_qty'] < quantity:
            return error_response(message="재고가 부족합니다.")

        item['quantity'] = quantity
        item['subtotal'] = item['product_dis_price'] * quantity

        save_cart_data(r, request.user.pk, cart)

        return success_response(
            data={"cart_item_id": cart_item_id, "quantity": quantity}
        )

    def delete(self, request, cart_item_id):
        r = get_redis()
        cart = get_cart_data(r, request.user.pk)
        item = get_cart_item_or_404(cart, cart_item_id)

        if not cart:
            return error_response(
                message="장바구니가 비어 있습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        if not item:
            return error_response(
                message="장바구니 항목을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        cart['items'] = [i for i in cart['items'] if i['cart_item_id'] != cart_item_id]

        # 장바구니가 비었으면 키 삭제
        if not cart['items']:
            r.delete(get_cart_key(request.user.pk))
        else:
            save_cart_data(r, request.user.pk, cart)

        return success_response(data=None, message="상품이 삭제되었습니다.")
