from django.core.paginator import Paginator
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from common.response import error_response, extract_first_error, success_response
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
    주문 조회 헬퍼 함수
    OrderDetailView, OrderCancelView 양쪽에서 동일한 조회 로직이
    중복되어 함수로 분리
    조회 성공 시 order 반환, 실패 시 None 반환
    """
    try:
        return Order.objects.get(order_id=order_id, user_id=user)
    except Order.DoesNotExist:
        return None


class OrderView(APIView):
    """
    POST /orders  - 주문 생성
    GET  /orders  - 내 주문 목록 조회
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
    GET /orders/{order_id} - 주문 상세 조회
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
    PATCH /orders/{order_id}/cancel - 주문 취소
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