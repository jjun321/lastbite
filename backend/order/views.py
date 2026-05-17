from django.core.paginator import Paginator
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from common.response import error_response, extract_first_error, success_response
from notification.utils import notify_order_cancelled, notify_order_received
from order.models.order import Order
from order.models.orderProdList import OrderProdList
from order.serializers import (
    OrderCreateSerializer,
    OrderDetailSerializer,
    OrderListSerializer,
    OrderItemDetailSerializer
)
from product.models.product import Product


def get_order_or_404(order_id, user):
    """
    주문 조회 헬퍼 함수.
    store_id 를 select_related 로 미리 로드해
    notify_order_received 에서 발생하는 추가 쿼리를 방지.
    조회 성공 시 order 반환, 실패 시 None 반환.
    """
    try:
        return Order.objects.select_related(
            "store_id", "store_id__user_id"
        ).get(order_id=order_id, user_id=user)
    except Order.DoesNotExist:
        return None


class OrderView(APIView):
    """
    POST /orders — 주문 생성
    GET  /orders — 내 주문 목록 조회
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = OrderCreateSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return error_response(
                message=extract_first_error(serializer.errors),
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        order, total_price = serializer.save()

        # N01: 주문 접수 알림 → 점주에게 발송
        # 알림 실패가 주문 응답을 막으면 안 되므로 예외를 조용히 처리
        try:
            notify_order_received(order)
        except Exception:
            pass

        return success_response(
            data={
                "order_id": order.order_id,
                "order_status": order.order_status,
                "pickup_dt": order.pickup_dt,
                "order_dt": order.reg_dt,
                "total_price": total_price,
            },
            status_code=status.HTTP_201_CREATED,
        )

    def get(self, request):
        status_param = request.query_params.get('status')
        page = int(request.query_params.get('page', 0))
        size = int(request.query_params.get('size', 20))

        orders = Order.objects.filter(user_id=request.user).order_by('-reg_dt')

        # status 필터 적용
        if status_param == 'ACTIVE':
            orders = orders.filter(order_status__in=['S01', 'S02', 'S03'])
        elif status_param in ['S01', 'S02', 'S03', 'S04']:
            orders = orders.filter(order_status=status_param)

        # 페이지네이션 (page는 0-based)
        paginator = Paginator(orders, size)
        page_obj = paginator.get_page(page + 1)

        serializer = OrderListSerializer(page_obj, many=True)
        return success_response(data=serializer.data)


class OrderDetailView(APIView):
    """
    GET /orders/{order_id} — 주문 상세 조회
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, order_id):
        order = get_order_or_404(order_id, request.user)
        if not order:
            return error_response(
                message="주문을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        serializer = OrderDetailSerializer(order)
        return success_response(data=serializer.data)


class OrderCancelView(APIView):
    """
    PATCH /orders/{order_id}/cancel — 주문 취소
    S01 상태에서만 취소 가능, S02 이후 취소 불가 (ORD_002)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, order_id):
        order = get_order_or_404(order_id, request.user)
        if not order:
            return error_response(
                message="주문을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        if order.order_status == 'S04':
            return error_response(
                message="이미 취소된 주문입니다.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        if order.order_status != 'S01':
            return error_response(
                message="처리 중인 주문은 취소할 수 없습니다.",
                code="ORD_002",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        # 재고 복구 + 주문 취소 단일 트랜잭션
        with transaction.atomic():
            for item in order.orderprodlist_set.all():
                product = Product.objects.select_for_update().get(
                    product_id=item.product_id_id
                )
                product.product_count += item.order_prod_count
                product.save()

            order.order_status = 'S04'
            order.save()

        # N03: 주문 취소 알림 → 소비자에게 발송
        # 트랜잭션 외부에서 호출 (알림 실패가 취소 롤백을 유발하면 안 됨)
        try:
            notify_order_cancelled(order)
        except Exception:
            pass

        return success_response(
            data={
                "order_id": order.order_id,
                "order_status": order.order_status,
            },
            message="주문이 취소되었습니다.",
        )

class OrderItemDetailView(APIView):
    """
    GET /orders/{order_id}/items/{product_id}
    주문 내 특정 상품 상세 조회
    - 가격은 현재 product 테이블이 아닌 주문 시점 order_item 기준
    - 본인 주문만 접근 가능
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, order_id, product_id):
        # 1. 주문 존재 + 본인 소유 확인
        order = get_order_or_404(order_id, request.user)
        if not order:
            return error_response(
                message="주문을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # 2. 해당 주문 내 상품 조회
        try:
            order_item = (
                OrderProdList.objects
                .select_related('product_id__category_id')
                .prefetch_related('product_id__productimg_set__img_id')
                .get(order_id=order, product_id=product_id)
            )
        except OrderProdList.DoesNotExist:
            return error_response(
                message="해당 주문에 존재하지 않는 상품입니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        serializer = OrderItemDetailSerializer(order_item)
        return success_response(data=serializer.data)

class OrderReorderView(APIView):
    """
    POST /orders/{order_id}/reorder/

    이전 주문과 동일한 장바구니 내용을 Redis에 복제.
    프론트는 이 응답을 받아 예약 확인 전 단계(장바구니 화면)로 이동.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, order_id):
        import json
        import uuid
        import redis
        from django.conf import settings

        order = get_order_or_404(order_id, request.user)
        if not order:
            return error_response(
                message="주문을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        items = order.orderprodlist_set.select_related('product_id').all()
        if not items:
            return error_response(message="주문 상품이 없습니다.")

        # ── 현재 재고 및 매장 상태 확인 ─────────────────────────────────────
        store = order.store_id
        if store.is_deleted or store.is_closed:
            return error_response("해당 매장이 현재 운영 중이지 않습니다.")

        cart_items = []
        for item in items:
            product = item.product_id
            if product.is_deleted:
                continue   # 삭제된 상품은 재주문 목록에서 제외
            if (product.product_count or 0) <= 0:
                continue   # 품절 상품 제외

            cart_items.append({
                "cart_item_id":      str(uuid.uuid4()),
                "product_id":        product.product_id,
                "product_name":      product.product_name,
                "product_dis_price": product.product_dis_price,
                "product_ori_price": product.product_ori_price,
                "quantity":          item.order_prod_count,
                "product_qty":       product.product_count,
                "subtotal":          product.product_dis_price * item.order_prod_count,
            })

        if not cart_items:
            return error_response("재주문 가능한 상품이 없습니다. (품절 또는 삭제된 상품)")

        # ── Redis 장바구니에 덮어씌우기 ─────────────────────────────────────
        r         = redis.from_url(settings.REDIS_URL, decode_responses=True)
        cart_key  = f"cart:{request.user.user_id}"
        CART_TTL  = 60 * 60 * 24 * 7  # 7일

        cart_data = {
            "store_id":   store.store_id,
            "store_name": store.store_name,
            "items":      cart_items,
        }
        r.setex(cart_key, CART_TTL, json.dumps(cart_data, ensure_ascii=False))

        return success_response(
            data={
                "store_id":   store.store_id,
                "store_name": store.store_name,
                "items":      cart_items,
                "item_count": len(cart_items),
            },
            message="장바구니에 이전 주문이 담겼습니다.",
        )