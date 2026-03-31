from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from cart.models.cart import Cart
from cart.models.cartItem import CartItem
from cart.serializers import (
    CartItemAddSerializer,
    CartItemOutputSerializer,
    CartItemUpdateSerializer,
)
from common.response import error_response, success_response
from product.models.product import Product


class CartView(APIView):
    """
    GET    /cart/  - 장바구니 조회
    DELETE /cart/  - 장바구니 전체 비우기
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            cart = Cart.objects.get(user_id=request.user)
        except Cart.DoesNotExist:
            return success_response(data=None)

        items = cart.items.select_related('product_id').all()
        serializer = CartItemOutputSerializer(items, many=True)

        total_price = sum(item['subtotal'] for item in serializer.data)
        total_quantity = sum(item['quantity'] for item in serializer.data)

        return success_response(
            data={
                "store_id": cart.store_id_id,
                "store_name": cart.store_id.store_name if cart.store_id else None,
                "items": serializer.data,
                "total_quantity": total_quantity,
                "total_price": total_price,
            }
        )

    def delete(self, request):
        try:
            cart = Cart.objects.get(user_id=request.user)
        except Cart.DoesNotExist:
            return success_response(data=None, message="장바구니가 이미 비어 있습니다.")

        cart.items.all().delete()
        cart.store_id = None
        cart.save()

        return success_response(data=None, message="장바구니가 비워졌습니다.")


class CartItemView(APIView):
    """
    POST /cart/items/ - 장바구니 상품 추가
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CartItemAddSerializer(data=request.data)
        if not serializer.is_valid():
            first_error = list(serializer.errors.values())[0][0]
            return error_response(message=str(first_error))

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

        # 장바구니 없으면 생성
        cart, _ = Cart.objects.get_or_create(user_id=request.user)

        # 다른 매장 상품이 담겨있는지 확인
        if cart.store_id and cart.store_id_id != product.store_id_id:
            return error_response(
                message="다른 매장의 상품은 함께 담을 수 없습니다. 장바구니를 먼저 비워주세요."
            )

        # 매장 업데이트
        if not cart.store_id:
            cart.store_id = product.store_id
            cart.save()

        # 이미 담긴 상품이면 수량 누적
        existing_item = cart.items.filter(product_id=product).first()
        if existing_item:
            existing_item.quantity += quantity
            existing_item.save()
            cart_item_id = existing_item.cart_item_id
        else:
            cart_item = CartItem.objects.create(
                cart_id=cart,
                product_id=product,
                quantity=quantity,
            )
            cart_item_id = cart_item.cart_item_id

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
            first_error = list(serializer.errors.values())[0][0]
            return error_response(message=str(first_error))

        try:
            cart = Cart.objects.get(user_id=request.user)
            cart_item = CartItem.objects.get(cart_item_id=cart_item_id, cart_id=cart)
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return error_response(
                message="장바구니 항목을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # 재고 확인
        quantity = serializer.validated_data['quantity']
        product = cart_item.product_id
        if product.product_count is not None and product.product_count < quantity:
            return error_response(message="재고가 부족합니다.")

        cart_item.quantity = quantity
        cart_item.save()

        return success_response(
            data={"cart_item_id": cart_item.cart_item_id, "quantity": cart_item.quantity}
        )

    def delete(self, request, cart_item_id):
        try:
            cart = Cart.objects.get(user_id=request.user)
            cart_item = CartItem.objects.get(cart_item_id=cart_item_id, cart_id=cart)
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return error_response(
                message="장바구니 항목을 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        cart_item.delete()

        # 장바구니가 비었으면 store_id 초기화
        if not cart.items.exists():
            cart.store_id = None
            cart.save()

        return success_response(data=None, message="상품이 삭제되었습니다.")
