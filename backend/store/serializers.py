from django.utils.dateparse import parse_date
from rest_framework import serializers
from store.models.store import Store
from store.models.store_working_time import StoreWorkingTime
from store.models.off_date import OffDate
from store.utils import haversine_km, is_off_today, get_today_open_close
from product.models.product import Product

class StoreListSerializer(serializers.ModelSerializer):
    #GET /stores/ — 매장 목록
    store_id = serializers.IntegerField(source='pk')
    is_closed = serializers.BooleanField()
    distance_km = serializers.SerializerMethodField()
    today_open = serializers.SerializerMethodField()
    today_close = serializers.SerializerMethodField()
    is_off_today = serializers.SerializerMethodField()
    rep_product = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_lat', 'store_long',
            'is_closed', 'distance_km',
            'today_open', 'today_close', 'is_off_today',
            'rep_product','is_favorite',
        ]

    def get_distance_km(self, obj):
        ref_lat = self.context.get('ref_lat')
        ref_lon = self.context.get('ref_lon')
        if ref_lat is None or ref_lon is None:
            return None
        if obj.store_lat is None or obj.store_long is None:
            return None
        return round(haversine_km(ref_lat, ref_lon, float(obj.store_lat), float(obj.store_long)), 2)

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

    def get_is_favorite(self, obj):
        # context에 미리 로드된 집합에서 O(1) 조회 → N+1 없음
        favorite_ids = self.context.get('favorite_store_ids', set())
        return obj.pk in favorite_ids


class StoreDetailSerializer(serializers.ModelSerializer):
    #GET /stores/{store_id}/ — 매장 상세
    store_id = serializers.IntegerField(source='pk')
    is_closed = serializers.BooleanField()
    is_off_today = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_desc','store_lat', 'store_long',
            'is_closed', 'is_off_today', 'is_favorite',
        ]

    def get_is_off_today(self, obj):
        return is_off_today(obj)

    def get_is_favorite(self, obj):
        # context에 미리 로드된 집합에서 O(1) 조회
        favorite_ids = self.context.get('favorite_store_ids', set())
        return obj.pk in favorite_ids


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


# ------- 점주 전용 시리얼라이저 --------

# 영업일과 함께 영업 시간을 설정하는 방식으로 되어있음
# 따라서 요청에서 영업일과 영업시간을 조합해야함
class OwnerStoreCreateSerializer(serializers.ModelSerializer):
    # POST /owner/stores/ 가게 최초 등록
    working_times = serializers.DictField(write_only=True, required=False)


    class Meta:
        model = Store
        fields = [
            'store_name', 'store_address',
            'store_desc', 'store_img_id',
            'store_lat', 'store_long',
            'working_times'
        ]

    def validate_store_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("가게 이름을 입력해주세요.")
        return value.strip()

    def validate_store_address(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("가게 주소를 입력해주세요.")
        return value.strip()

    def create(self, validated_data):
        working_times = validated_data.pop('working_times', [])
        store = Store.objects.create(**validated_data)
        working_days = [
            StoreWorkingTime(
                store_id=store,
                working_day=f'D{i:02d}',
                start_time=working_times.get('start_time'),
                end_time=working_times.get('end_time')
            ) for i in range(1, 8)  # 월(D01) ~ 일(D07)
        ]
        StoreWorkingTime.objects.bulk_create(working_days)

        return store


class OwnerStoreUpdateSerializer(serializers.ModelSerializer):
    #PATCH /owner/stores/{store_id}/ 가게 정보 수정
    """
    운영시간: {"start_time":"09:00","end_time":"22:00"}
    휴무일:
    [
        {"off_dt": "2024-05-01", "off_desc": "근로자의 날"},
        {"off_dt": "2024-05-05", "off_desc": "어린이날"}
    ]
    """
    working_times = serializers.DictField(write_only=True, required=False)
    off_dates = serializers.ListField(
        child=serializers.DictField(), write_only=True, required=False
    )

    class Meta:
        model = Store
        fields = [
            'store_name', 'store_address',
            'store_desc', 'store_img_id',
            'store_lat', 'store_long',
            'working_times', 'off_dates'
        ]
        # 모두 선택적 수정 허용
        extra_kwargs = {f: {'required': False} for f in fields}

    def validate_working_times(self, value):
        try:
            h, m = value['start_time'].split(':')
            assert 0 <= int(h) <= 23 and 0 <= int(m) <= 59
        except Exception:
            raise serializers.ValidationError(f"{value}의 형식이 올바르지 않습니다. (HH:MM)")

    def validate_off_dates(self, value):
        from store.utils import get_today_kst
        for od in value :
            print(type(od['off_dt']))
            if parse_date(od['off_dt']) < get_today_kst():
                raise serializers.ValidationError("과거 날짜는 휴무일로 등록할 수 없습니다.")
        return value

    def update(self, instance, validated_data):
        working_times = validated_data.pop('working_times', None)
        off_dates = validated_data.pop('off_dates', None)

        # Store 기본 필드 업데이트
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # 운영시간 전달 시 전체 교체(upsert)
        if working_times is not None:
            instance.storeworkingtime_set.all().delete()
            working_times = [
                StoreWorkingTime(
                    store_id=instance,
                    working_day=f'D{i:02d}',
                    start_time=working_times.get('start_time'),
                    end_time=working_times.get('end_time')
                ) for i in range(1, 8)  # 월(D01) ~ 일(D07)
            ]
            StoreWorkingTime.objects.bulk_create(working_times)

        if off_dates is not None :
            for od in off_dates:
                OffDate.objects.create(
                    store_id=instance,
                    user_id=instance.user_id,  # 점주 연결
                    off_dt=od['off_dt'],
                    off_desc=od['off_desc'],
                )
        return instance


class OwnerStoreDetailSerializer(serializers.ModelSerializer):
    #GET /owner/stores/me/ 점주 본인 가게 정보 조회
    store_id = serializers.IntegerField(source='pk', read_only=True)
    store_img_url = serializers.SerializerMethodField()
    working_times = serializers.SerializerMethodField()
    off_dates = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_desc', 'store_img_id', 'store_img_url',
            'store_lat', 'store_long',
            'is_closed',
            'working_times', 'off_dates',
            'reg_dt',
        ]

    def get_store_img_url(self, obj):
        if obj.store_img_id:
            return obj.store_img_id.img_url
        return None

    def get_working_times(self, obj):
        wts = obj.storeworkingtime_set.all().order_by('working_day')
        return [
            {
                'working_time_id': wt.working_time_id,
                'working_day': wt.working_day,
                'start_time': wt.start_time.strftime('%H:%M'),
                'end_time': wt.end_time.strftime('%H:%M'),
            }
            for wt in wts
        ]

    def get_off_dates(self, obj):
        from store.utils import get_today_kst
        today = get_today_kst()
        offs = obj.offdate_set.filter(off_dt__gte=today).order_by('off_dt')
        return [
            {
                'closed_date_id': od.closed_date_id,
                'off_dt': od.off_dt.strftime('%Y-%m-%d'),
                'off_desc': od.off_desc,
            }
            for od in offs
        ]


class OffDateCreateSerializer(serializers.ModelSerializer):
    #POST /owner/stores/{store_id}/off-dates/ 휴무일 등록

    class Meta:
        model = OffDate
        fields = ['off_dt', 'off_desc']

    def validate_off_dt(self, value):
        from store.utils import get_today_kst
        if value < get_today_kst():
            raise serializers.ValidationError("과거 날짜는 휴무일로 등록할 수 없습니다.")
        return value

