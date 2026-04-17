"""
order/owner_views.py
점주 전용 주문 관리 뷰

GET   /owner/stores/{store_id}/orders/                     들어온 주문 (S01)
GET   /owner/stores/{store_id}/orders/history/             주문 내역 (S02/S03/S04)
GET   /owner/stores/{store_id}/orders/{order_id}/          주문 상세
PATCH /owner/stores/{store_id}/orders/{order_id}/accept/   주문 수락 S01→S02
PATCH /owner/stores/{store_id}/orders/{order_id}/cancel/   주문 취소 S01·S02→S04
PATCH /owner/stores/{store_id}/orders/{order_id}/complete/ 픽업 완료 S02→S03
"""

from django.core.paginator import Paginator
from django.db import transaction
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import status

from common.response import success_response, error_response
from store.models.store import Store
from order.models.order import Order
from product.models.product import Product
from order.owner_serializers import (
    OwnerOrderListSerializer,
    OwnerOrderDetailSerializer,
)
from notification.utils import (
    notify_order_accepted,
    notify_order_cancelled,
    notify_order_completed,
)




# ── 공통 헬퍼 ──────────────────────────────────────────────────────────────────

def check_owner_type(user):
    #점주(U02) 여부 확인. 아니면 error_response 반환
    if user.user_type != 'U02':
        return error_response("점주 전용 기능입니다.", status_code=status.HTTP_403_FORBIDDEN)
    return None


def get_owner_store(user, store_id):
    #요청 유저 소유 + 미삭제 매장 반환. 없으면 None
    try:
        return Store.objects.get(pk=store_id, user_id=user, is_deleted=False)
    except Store.DoesNotExist:
        return None


def get_store_order(store, order_id):
    """
    해당 매장 소속 주문 반환.
    user_id를 select_related로 미리 로드하여 알림 발송 시 추가 쿼리 방지.
    """
    try:
        return (
            Order.objects
            .select_related('user_id')
            .prefetch_related('orderprodlist_set__product_id')
            .get(pk=order_id, store_id=store)
        )
    except Order.DoesNotExist:
        return None


# ── 뷰 ────────────────────────────────────────────────────────────────────────

class OwnerOrderIncomingView(APIView):
    """
    GET /owner/stores/{store_id}/orders/
    들어온 주문 탭 — S01(주문 접수) 상태만 최신순
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        try:
            page = max(0, int(request.query_params.get('page', 0)))
            size = min(int(request.query_params.get('size', 20)), 50)
        except ValueError:
            return error_response("page/size 값이 올바르지 않습니다.")

        qs = (
            Order.objects
            .filter(store_id=store, order_status='S01')
            .select_related('user_id')
            .prefetch_related('orderprodlist_set__product_id')
            .order_by('-reg_dt')
        )

        paginator = Paginator(qs, size)
        page_obj  = paginator.get_page(page + 1)

        serializer = OwnerOrderListSerializer(page_obj, many=True)
        return success_response(data={
            'total':  paginator.count,
            'page':   page,
            'size':   size,
            'orders': serializer.data,
        })


class OwnerOrderHistoryView(APIView):
    """
    GET /owner/stores/{store_id}/orders/history/
    주문 내역 탭 — S02/S03/S04 상태, status 쿼리파라미터로 필터 가능
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        try:
            page = max(0, int(request.query_params.get('page', 0)))
            size = min(int(request.query_params.get('size', 20)), 50)
        except ValueError:
            return error_response("page/size 값이 올바르지 않습니다.")

        # 주문 내역은 S02·S03·S04 전체가 기본
        # ?status=S02 처럼 단일 필터도 허용
        status_param   = request.query_params.get('status')
        history_status = ['S02', 'S03', 'S04']

        qs = (
            Order.objects
            .filter(store_id=store, order_status__in=history_status)
            .select_related('user_id')
            .prefetch_related('orderprodlist_set__product_id')
            .order_by('-reg_dt')
        )

        if status_param in history_status:
            qs = qs.filter(order_status=status_param)

        paginator = Paginator(qs, size)
        page_obj  = paginator.get_page(page + 1)

        serializer = OwnerOrderListSerializer(page_obj, many=True)
        return success_response(data={
            'total':  paginator.count,
            'page':   page,
            'size':   size,
            'orders': serializer.data,
        })


class OwnerOrderDetailView(APIView):
    """
    GET /owner/stores/{store_id}/orders/{order_id}/
    주문 상세 — 주문 메뉴 + 결제 금액 + 주문자 정보
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id, order_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        order = get_store_order(store, order_id)
        if order is None:
            return error_response("주문을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OwnerOrderDetailSerializer(order)
        return success_response(data=serializer.data)


class OwnerOrderAcceptView(APIView):
    """
    PATCH /owner/stores/{store_id}/orders/{order_id}/accept/
    주문 수락 — S01 → S02, 소비자에게 수락 알림(N05)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, store_id, order_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        order = get_store_order(store, order_id)
        if order is None:
            return error_response("주문을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        if order.order_status != 'S01':
            return error_response(
                "접수 상태(S01)인 주문만 수락할 수 있습니다.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        order.order_status = 'S02'
        order.save(update_fields=['order_status'])

        # N05: 주문 수락 알림 → 소비자
        try:
            notify_order_accepted(order)
        except Exception:
            pass

        return success_response(
            data={'order_id': order.order_id, 'order_status': order.order_status},
            message="주문을 수락했습니다.",
        )


class OwnerOrderCancelView(APIView):
    """
    PATCH /owner/stores/{store_id}/orders/{order_id}/cancel/
    주문 취소 — S01 → S04, 재고 복구, 소비자에게 취소 알림(N03)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, store_id, order_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        order = get_store_order(store, order_id)
        if order is None:
            return error_response("주문을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        if order.order_status not in 'S01':
            return error_response(
                "접수(S01) 상태인 주문만 취소할 수 있습니다.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        # 재고 복구 + 상태 변경을 단일 트랜잭션으로 처리
        with transaction.atomic():
            for item in order.orderprodlist_set.all():
                product = Product.objects.select_for_update().get(
                    product_id=item.product_id_id
                )
                product.product_count += item.order_prod_count
                product.save(update_fields=['product_count'])

            order.order_status = 'S04'
            order.save(update_fields=['order_status'])

        # N03: 주문 취소 알림 → 소비자
        # 트랜잭션 외부에서 호출 (알림 실패가 취소 롤백을 유발하면 안 됨)
        try:
            notify_order_cancelled(order)
        except Exception:
            pass

        return success_response(
            data={'order_id': order.order_id, 'order_status': order.order_status},
            message="주문을 취소했습니다.",
        )


class OwnerOrderCompleteView(APIView):
    """
    PATCH /owner/stores/{store_id}/orders/{order_id}/complete/
    픽업 완료 처리 — S02 → S03, 소비자에게 완료 알림(N02)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, store_id, order_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        order = get_store_order(store, order_id)
        if order is None:
            return error_response("주문을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        if order.order_status != 'S02':
            return error_response(
                "처리중(S02) 상태인 주문만 완료 처리할 수 있습니다.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        order.order_status = 'S03'
        order.save(update_fields=['order_status'])

        # N02: 주문 처리 완료 알림 → 소비자
        try:
            notify_order_completed(order)
        except Exception:
            pass

        return success_response(
            data={'order_id': order.order_id, 'order_status': order.order_status},
            message="주문을 완료 처리했습니다.",
        )