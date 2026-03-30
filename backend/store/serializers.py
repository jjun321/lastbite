from rest_framework import serializers
from store.models.store import Store
from store.models.store_working_time import StoreWorkingTime
from store.utils import haversine_km, is_off_today, get_today_open_close


class StoreListSerializer(serializers.ModelSerializer):
    #GET /stores/ — 매장 목록
    store_id = serializers.IntegerField(source='pk')
    is_closed = serializers.BooleanField()
    distance_km = serializers.SerializerMethodField()
    today_open = serializers.SerializerMethodField()
    today_close = serializers.SerializerMethodField()
    is_off_today = serializers.SerializerMethodField()
    rep_product = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_lat', 'store_lon',
            'is_closed', 'distance_km',
            'today_open', 'today_close', 'is_off_today',
            'rep_product',
        ]

    def get_distance_km(self, obj):
        ref_lat = self.context.get('ref_lat')
        ref_lon = self.context.get('ref_lon')
        if ref_lat is None or ref_lon is None:
            return None
        if obj.store_lat is None or obj.store_lon is None:
            return None
        return round(haversine_km(ref_lat, ref_lon, float(obj.store_lat), obj.store_lon), 2)

    def get_today_open(self, obj):
        if is_off_today(obj):
            return None
        open_t, _ = get_today_open_close(obj)
        return open_t

    def get_today_close(self, obj):
        if is_off_today(obj):
            return None
        _, close_t = get_today_open_close(obj)
        return close_t

    def get_is_off_today(self, obj):
        return is_off_today(obj)

    def get_rep_product(self, obj):
        #할인가 최저 제품 1건
        product = (
            obj.product_set
            .filter(is_deleted=False, product_dis_price__isnull=False)
            .order_by('product_dis_price')
            .first()
        )
        if not product:
            return None
        ori = product.product_ori_price or 0
        dis = product.product_dis_price or 0
        rate = int((1 - dis / ori) * 100) if ori else 0
        return {
            'product_name': product.product_name,
            'dis_price': dis,
            'discount_rate': rate,
        }


class StoreDetailSerializer(serializers.ModelSerializer):
    #GET /stores/{store_id}/ — 매장 상세
    store_id = serializers.IntegerField(source='pk')
    is_closed = serializers.BooleanField()
    is_off_today = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_lat', 'store_lon',
            'is_closed', 'is_off_today',
        ]

    def get_is_off_today(self, obj):
        return is_off_today(obj)


class StoreWorkingTimeSerializer(serializers.ModelSerializer):
    #GET /stores/{store_id}/hours/ — 운영시간
    working_time_id = serializers.IntegerField(source='pk')
    day_of_week = serializers.CharField(source='working_day')
    open_time = serializers.SerializerMethodField()
    close_time = serializers.SerializerMethodField()

    class Meta:
        model = StoreWorkingTime
        fields = ['working_time_id', 'day_of_week', 'open_time', 'close_time']

    def get_open_time(self, obj):
        return obj.start_time.strftime('%H:%M')

    def get_close_time(self, obj):
        return obj.end_time.strftime('%H:%M')