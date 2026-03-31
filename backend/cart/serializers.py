from rest_framework import serializers

from cart.models.cartItem import CartItem


# ─── 장바구니 조회 ──────────────────────────────────────

class CartItemOutputSerializer(serializers.ModelSerializer):
    product_id = serializers.IntegerField(source='product_id_id')
    product_name = serializers.CharField(source='product_id.product_name')
    product_dis_price = serializers.IntegerField(source='product_id.product_dis_price')
    product_qty = serializers.IntegerField(source='product_id.product_count')  # 재고 실시간 조회
    subtotal = serializers.SerializerMethodField()

    class Meta:
        model = CartItem
        fields = [
            'cart_item_id',
            'product_id',
            'product_name',
            'product_dis_price',
            'quantity',
            'product_qty',
            'subtotal',
        ]

    def get_subtotal(self, obj):
        if obj.product_id.product_dis_price is None:
            return 0
        return obj.product_id.product_dis_price * obj.quantity


# ─── 장바구니 상품 추가 ─────────────────────────────────

class CartItemAddSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)


# ─── 장바구니 수량 변경 ────────────────────────────────

class CartItemUpdateSerializer(serializers.Serializer):
    quantity = serializers.IntegerField(min_value=1)
