from rest_framework import serializers
from order.models.order import Order
from order.models.orderProdList import OrderProdList


class OwnerOrderItemSerializer(serializers.ModelSerializer):
    #주문 내 상품 행
    product_id   = serializers.IntegerField(source='product_id_id')
    product_name = serializers.CharField(source='product_id.product_name')
    quantity     = serializers.IntegerField(source='order_prod_count')
    subtotal     = serializers.SerializerMethodField()

    class Meta:
        model  = OrderProdList
        fields = [
            'product_id', 'product_name',
            'quantity', 'product_dis_price', 'product_ori_price', 'subtotal',
        ]

    def get_subtotal(self, obj):
        return obj.product_dis_price * obj.order_prod_count


class OwnerOrderListSerializer(serializers.ModelSerializer):
    #들어온 주문 / 주문 내역 목록 카드
    order_dt    = serializers.DateTimeField(source='reg_dt', format="%Y-%m-%dT%H:%M:%SZ")
    pickup_dt   = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")
    # 대표 상품명 + 건수 요약 (e.g. "베이글 외 2건")
    item_summary = serializers.SerializerMethodField()
    total_price  = serializers.SerializerMethodField()
    # 주문자 이름 (목록에서 미리 표시)
    buyer_name   = serializers.CharField(source='user_id.user_name')

    class Meta:
        model  = Order
        fields = [
            'order_id', 'order_status',
            'buyer_name', 'item_summary',
            'total_price', 'pickup_dt', 'order_dt',
        ]

    def get_item_summary(self, obj):
        items = list(obj.orderprodlist_set.select_related('product_id').all())
        if not items:
            return "-"
        first = items[0].product_id.product_name
        rest  = len(items) - 1
        return first if rest == 0 else f"{first} 외 {rest}건"

    def get_total_price(self, obj):
        return sum(
            item.product_dis_price * item.order_prod_count
            for item in obj.orderprodlist_set.all()
        )


class OwnerOrderDetailSerializer(serializers.ModelSerializer):
    #주문 상세 조회시, 주문 메뉴 + 결제 금액 + 주문자 정보
    order_dt  = serializers.DateTimeField(source='reg_dt', format="%Y-%m-%dT%H:%M:%SZ")
    pickup_dt = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")
    items     = OwnerOrderItemSerializer(source='orderprodlist_set', many=True)

    # 결제 금액 블록
    total_ori_price = serializers.SerializerMethodField()
    total_dis_price = serializers.SerializerMethodField()   # 실 결제금액
    total_discount  = serializers.SerializerMethodField()   # 절약 금액

    # 주문자 정보 블록
    buyer = serializers.SerializerMethodField()

    class Meta:
        model  = Order
        fields = [
            'order_id', 'order_status',
            'pickup_dt', 'order_dt',
            'items',
            'total_ori_price', 'total_dis_price', 'total_discount',
            'buyer',
        ]

    def get_total_ori_price(self, obj):
        return sum(
            item.product_ori_price * item.order_prod_count
            for item in obj.orderprodlist_set.all()
        )

    def get_total_dis_price(self, obj):
        return sum(
            item.product_dis_price * item.order_prod_count
            for item in obj.orderprodlist_set.all()
        )

    def get_total_discount(self, obj):
        return self.get_total_ori_price(obj) - self.get_total_dis_price(obj)

    def get_buyer(self, obj):
        u = obj.user_id
        return {
            'user_id':    u.user_id,
            'user_name':  u.user_name,
            'user_phone': u.user_phone,
        }