from django.db import transaction
from rest_framework import serializers

from order.models.order import Order
from order.models.orderProdList import OrderProdList
from product.models.product import Product
from store.models.off_date import OffDate
from store.models.store import Store
from store.models.store_working_time import StoreWorkingTime
from datetime import datetime, timedelta, date

def _is_pickup_valid(working_time, pickup_dt) -> bool:
    """
    픽업 시간이 운영시간 내에 있는지 판단.
    end_day_offset=1 (자정 넘기는 영업) 처리 포함.
    """
    offset = getattr(working_time, 'end_day_offset', 0)

    # KST 기준 datetime으로 변환하여 비교
    pickup_date = pickup_dt.date()
    open_dt  = datetime.combine(pickup_date, working_time.start_time)
    close_dt = datetime.combine(pickup_date + timedelta(days=offset), working_time.end_time)

    # offset=1이고 end_time=00:00이면 close_dt = 내일 00:00 (자정 정각 마감)
    # offset=0이고 end_time=00:00이면 close_dt = 오늘 00:00 → 영업시간 0분으로 비정상
    # → 이 경우는 validate_working_times에서 사전 차단

    pickup_naive = pickup_dt.replace(tzinfo=None)
    return open_dt <= pickup_naive <= close_dt



# 요일 코드 매핑 (Python weekday() 기준)
# 0=월, 1=화, 2=수, 3=목, 4=금, 5=토, 6=일
'''
WEEKDAY_CODE_MAP = {
    0: 'D02',  # 월
    1: 'D03',  # 화
    2: 'D04',  # 수
    3: 'D05',  # 목
    4: 'D06',  # 금
    5: 'D07',  # 토
    6: 'D01',  # 일
}
'''
WEEKDAY_CODE_MAP = {i: f'D{i+1:02d}' for i in range(7)}


# ─── Mixin: total_price 계산 공통화 ──────────────────────

class TotalPriceMixin:
    """
    OrderListSerializer, OrderDetailSerializer 양쪽에서
    동일한 get_total_price 로직이 중복되어 Mixin으로 분리
    """
    def get_total_price(self, obj):
        return sum(
            item.product_dis_price * item.order_prod_count
            for item in obj.orderprodlist_set.all()
        )


# ─── 주문 생성 ───────────────────────────────────────────

class OrderItemInputSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    store_id = serializers.IntegerField()
    pickup_dt = serializers.DateTimeField()
    items = OrderItemInputSerializer(many=True)

    def validate_store_id(self, value):
        try:
            store = Store.objects.get(store_id=value, is_deleted=False)
        except Store.DoesNotExist:
            raise serializers.ValidationError("존재하지 않는 매장입니다.")
        if store.is_closed:
            raise serializers.ValidationError("현재 마감된 매장입니다.")
        # DB 이중 조회 방지: validate()에서 재사용할 수 있도록 캐싱
        self._store = store
        return value

    def validate(self, attrs):
        # validate_store_id에서 이미 조회한 store 재사용 (DB 쿼리 절약)
        store = self._store
        pickup_dt = attrs['pickup_dt']
        items = attrs['items']

        # 1. 휴무일 체크
        pickup_date = pickup_dt.date()
        if OffDate.objects.filter(store_id=store, off_dt=pickup_date).exists():
            raise serializers.ValidationError({"pickup_dt": "해당 날짜는 매장 휴무일입니다."})

        # 2. 운영시간 체크
        day_code = WEEKDAY_CODE_MAP[pickup_dt.weekday()]
        working_time = StoreWorkingTime.objects.filter(
            store_id=store,
            working_day=day_code,
        ).first()

        if not working_time:
            raise serializers.ValidationError({"pickup_dt": "해당 요일은 매장 운영일이 아닙니다."})


        # 3. 재고 체크
        for item in items:
            try:
                product = Product.objects.get(
                    product_id=item['product_id'],
                    store_id=store,
                    is_deleted=False,
                )
            except Product.DoesNotExist:
                raise serializers.ValidationError(
                    {"items": f"상품 ID {item['product_id']}가 존재하지 않습니다."}
                )
            if product.product_count is None or product.product_count < item['quantity']:
                raise serializers.ValidationError(
                    {"items": f"'{product.product_name}' 상품의 재고가 부족합니다."}
                )

        attrs['store'] = store
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        user = self.context['request'].user
        store = validated_data['store']
        pickup_dt = validated_data['pickup_dt']
        items = validated_data['items']

        # 주문 생성
        order = Order.objects.create(
            user_id=user,
            store_id=store,
            order_status='S01',
            pickup_dt=pickup_dt,
        )

        total_price = 0
        for item in items:
            # select_for_update: 동시 요청 시 재고 보호
            product = Product.objects.select_for_update().get(product_id=item['product_id'])

            # 재고 차감
            product.product_count -= item['quantity']
            product.save()

            # 주문 상품 생성
            OrderProdList.objects.create(
                order_id=order,
                product_id=product,
                order_prod_count=item['quantity'],
                product_dis_price=product.product_dis_price,
                product_ori_price=product.product_ori_price,
            )
            total_price += product.product_dis_price * item['quantity']

        return order, total_price





# ─── 주문 상세 조회 ──────────────────────────────────────

class OrderItemOutputSerializer(serializers.ModelSerializer):
    product_id = serializers.IntegerField(source='product_id_id')
    product_name = serializers.CharField(source='product_id.product_name')
    quantity = serializers.IntegerField(source='order_prod_count')
    subtotal = serializers.SerializerMethodField()

    class Meta:
        model = OrderProdList
        fields = ['product_id', 'product_name', 'quantity', 'product_dis_price', 'product_ori_price', 'subtotal']

    def get_subtotal(self, obj):
        return obj.product_dis_price * obj.order_prod_count

# ─── 주문 목록 조회 ──────────────────────────────────────

class OrderListSerializer(TotalPriceMixin, serializers.ModelSerializer):
    store_id = serializers.IntegerField(source='store_id_id')
    store_name = serializers.CharField(source='store_id.store_name')
    order_dt = serializers.DateTimeField(source='reg_dt')
    items = OrderItemOutputSerializer(source='orderprodlist_set', many=True)
    total_price = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['order_id', 'store_id', 'store_name', 'order_status', 'pickup_dt', 'order_dt', 'items', 'total_price']




class OrderDetailSerializer(TotalPriceMixin, serializers.ModelSerializer):
    store_id = serializers.IntegerField(source='store_id_id')
    store_name = serializers.CharField(source='store_id.store_name')
    order_dt = serializers.DateTimeField(source='reg_dt')
    items = OrderItemOutputSerializer(source='orderprodlist_set', many=True)
    total_price = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['order_id', 'store_id', 'store_name', 'order_status', 'pickup_dt', 'order_dt', 'items', 'total_price']

class OrderItemDetailSerializer(serializers.ModelSerializer):
    """GET /orders/{order_id}/items/{product_id}"""
    order_id      = serializers.IntegerField(source='order_id_id')
    product_id    = serializers.IntegerField(source='product_id_id')
    product_name  = serializers.CharField(source='product_id.product_name')
    product_desc  = serializers.CharField(source='product_id.product_desc')
    category_name = serializers.SerializerMethodField()
    discount_rate = serializers.SerializerMethodField()
    subtotal      = serializers.SerializerMethodField()
    img_url       = serializers.SerializerMethodField()

    class Meta:
        model  = OrderProdList
        fields = [
            'order_id',
            'product_id',
            'product_name',
            'product_desc',
            'category_name',
            'order_prod_count',
            'product_ori_price',
            'product_dis_price',
            'discount_rate',
            'subtotal',
            'img_url',
        ]

    def get_category_name(self, obj):
        # product → category JOIN
        category = obj.product_id.category_id
        return category.category_name if category else None

    def get_discount_rate(self, obj):
        # 주문 시점 가격 기준으로 계산 (product 테이블 아님)
        ori = obj.product_ori_price or 0
        dis = obj.product_dis_price or 0
        if ori == 0:
            return 0
        return int((1 - dis / ori) * 100)

    def get_subtotal(self, obj):
        return obj.product_dis_price * obj.order_prod_count

    def get_img_url(self, obj):
        # ProductImg → Image JOIN, 첫 번째 이미지 반환
        product_img = obj.product_id.productimg_set.select_related('img_id').first()
        if not product_img:
            return None
        return product_img.img_id.img_url