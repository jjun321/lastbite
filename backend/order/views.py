from django.core.paginator import Paginator
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from common.response import error_response, success_response
from order.models.order import Order
from order.serializers import (
    OrderCreateSerializer,
    OrderDetailSerializer,
    OrderListSerializer,
)
from product.models.product import Product


class OrderView(APIView):
    """
    POST /orders  - 주문 생성
    GET  /orders  - 내 주문 목록 조회
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = OrderCreateSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            # 첫 번째 에러 메시지 추출
            errors = serializer.errors
            first_key = list(errors.keys())[0]
            first_val = errors[first_key]
            if isinstance(first_val, list):
                message = str(first_val[0])
            elif isinstance(first_val, dict):
                message = str(list(first_val.values())[0][0])
            else:
                message = str(first_val)
            return error_response(message=message, status_code=status.HTTP_400_BAD_REQUEST)

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
        try:
            order = Order.objects.get(order_id=order_id, user_id=request.user)
        except Order.DoesNotExist:
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
        try:
            order = Order.objects.get(order_id=order_id, user_id=request.user)
        except Order.DoesNotExist:
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
