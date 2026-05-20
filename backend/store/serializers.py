import json
import uuid
import os
from django.conf import settings
from image.models.image import Image
from django.utils.dateparse import parse_date
from rest_framework import serializers
from store.models.store import Store
from store.models.store_working_time import StoreWorkingTime
from store.models.off_date import OffDate
from store.utils import haversine_km, is_off_today, get_today_open_close
from product.models.product import Product

ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
MAX_IMG_SIZE = 5 * 1024 * 1024  # 5MB


class JSONStringDictField(serializers.DictField):
    """
    multipart/form-data 요청에서 JSON 문자열로 전달된 dict 를 자동 파싱한다.
    DRF DictField 는 문자열을 dict 로 변환하지 못해 'not_a_dict' 로 실패하기 때문.
    """
    def to_internal_value(self, data):
        if isinstance(data, str):
            try:
                data = json.loads(data)
            except (TypeError, ValueError):
                self.fail('not_a_dict', input_type='str')
        return super().to_internal_value(data)


class JSONStringDictListField(serializers.ListField):
    """
    multipart/form-data 요청에서 JSON 문자열로 전달된 list[dict] 를 자동 파싱한다.
    QueryDict.getlist 가 [json_string] 형태로 꺼내오는 경우까지 처리한다.
    """
    def to_internal_value(self, data):
        if isinstance(data, str):
            try:
                data = json.loads(data)
            except (TypeError, ValueError):
                self.fail('not_a_list', input_type='str')
        elif isinstance(data, list) and len(data) == 1 and isinstance(data[0], str):
            try:
                data = json.loads(data[0])
            except (TypeError, ValueError):
                pass
        return super().to_internal_value(data)

def _save_store_image(image_file, user) -> Image:
    """
    매장 이미지 파일을 저장하고 Image 레코드를 반환.
    기존 product/owner_views.py의 save_product_image()와 동일한 패턴.
    """
    ext = image_file.name.rsplit('.', 1)[-1].lower()
    uuid_name = f"{uuid.uuid4()}.{ext}"
    save_dir = os.path.join(settings.MEDIA_ROOT, 'stores')
    os.makedirs(save_dir, exist_ok=True)

    with open(os.path.join(save_dir, uuid_name), 'wb+') as f:
        for chunk in image_file.chunks():
            f.write(chunk)

    return Image.objects.create(
        user_id=user,
        img_name=image_file.name,
        img_url=f"{settings.MEDIA_URL}stores/{uuid_name}",
        img_path=f"/uploads/stores/{uuid_name}",
        img_uuid_name=uuid_name,
    )

class StoreListSerializer(serializers.ModelSerializer):
    #GET /stores/ — 매장 목록
    store_id = serializers.IntegerField(source='pk')
    store_lat = serializers.FloatField()
    store_long = serializers.FloatField()
    is_closed = serializers.BooleanField()
    distance_km = serializers.SerializerMethodField()
    today_open = serializers.SerializerMethodField()
    today_close = serializers.SerializerMethodField()
    is_off_today = serializers.SerializerMethodField()
    rep_product = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    store_img_url = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_lat', 'store_long',
            'is_closed', 'distance_km',
            'today_open', 'today_close', 'is_off_today',
            'rep_product','is_favorite', 'store_img_url',
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

    def get_store_img_url(self, obj):
        if obj.store_img_id:
            return obj.store_img_id.img_url
        return None


class StoreDetailSerializer(serializers.ModelSerializer):
    #GET /stores/{store_id}/ — 매장 상세
    store_id = serializers.IntegerField(source='pk')
    store_lat = serializers.FloatField()
    store_long = serializers.FloatField()
    is_closed = serializers.BooleanField()
    is_off_today = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    store_img_url = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            'store_id', 'store_name', 'store_address',
            'store_desc','store_lat', 'store_long',
            'is_closed', 'is_off_today', 'is_favorite',
            'store_img_url',
        ]

    def get_is_off_today(self, obj):
        return is_off_today(obj)

    def get_is_favorite(self, obj):
        # context에 미리 로드된 집합에서 O(1) 조회
        favorite_ids = self.context.get('favorite_store_ids', set())
        return obj.pk in favorite_ids

    def get_store_img_url(self, obj):
        if obj.store_img_id:
            return obj.store_img_id.img_url
        return None


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
    working_times = JSONStringDictField(write_only=True, required=False)
    image_file = serializers.ImageField(write_only=True, required=False, allow_null=True)


    class Meta:
        model = Store
        fields = [
            'store_name', 'store_address',
            'store_desc',
            'store_lat', 'store_long',
            'working_times', 'image_file',
        ]

    def validate_store_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("가게 이름을 입력해주세요.")
        return value.strip()

    def validate_store_address(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("가게 주소를 입력해주세요.")
        return value.strip()

    def validate_image_file(self, value):
        if value is None:
            return value
        ext = value.name.rsplit('.', 1)[-1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise serializers.ValidationError("jpg, png, webp 형식만 업로드 가능합니다.")
        if value.size > MAX_IMG_SIZE:
            raise serializers.ValidationError("이미지 크기는 5MB 이하여야 합니다.")
        return value

    def create(self, validated_data):
        working_times = validated_data.pop('working_times', None)
        image_file = validated_data.pop('image_file', None)
        user = self.context['request'].user
        if image_file:
            image = _save_store_image(image_file, user)
            validated_data['store_img_id'] = image
        store = Store.objects.create(**validated_data)

        if working_times:
            working_days = [
                StoreWorkingTime(
                    store_id=store,
                    working_day=f'D{i:02d}',
                    start_time=working_times.get('start_time'),
                    end_time=working_times.get('end_time')
                ) for i in range(1, 8)
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
    working_times = JSONStringDictField(write_only=True, required=False)
    off_dates = JSONStringDictListField(
        child=serializers.DictField(), write_only=True, required=False
    )
    image_file = serializers.ImageField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = Store
        fields = [
            'store_name', 'store_address',
            'store_desc',
            'store_lat', 'store_long',
            'working_times', 'off_dates', 'image_file',
        ]
        # 모두 선택적 수정 허용
        extra_kwargs = {f: {'required': False} for f in [
            'store_name', 'store_address', 'store_desc',
            'store_lat', 'store_long',
            'working_times', 'off_dates', 'image_file',
        ]}

    def validate_working_times(self, value):
        start_time = value.get('start_time')
        end_time = value.get('end_time')
        end_day_offset = value.get('end_day_offset', 0)  # ← 추가

        # end_day_offset 범위 체크
        if end_day_offset not in (0, 1):
            raise serializers.ValidationError(
                "end_day_offset은 0(당일) 또는 1(익일)만 허용됩니다."
            )

        if start_time is not None:
            try:
                h, m = start_time.split(':')
                assert 0 <= int(h) <= 23 and 0 <= int(m) <= 59
            except Exception:
                raise serializers.ValidationError(
                    f"start_time '{start_time}'의 형식이 올바르지 않습니다. (HH:MM)"
                )

        if end_time is not None:
            try:
                h, m = end_time.split(':')
                assert 0 <= int(h) <= 23 and 0 <= int(m) <= 59
            except Exception:
                raise serializers.ValidationError(
                    f"end_time '{end_time}'의 형식이 올바르지 않습니다. (HH:MM)"
                )

        if end_time == '00:00' and end_day_offset == 0:
            raise serializers.ValidationError(
                "자정(00:00) 마감은 익일 마감이므로 end_day_offset을 1로 설정해야 합니다."
            )

        return value

    def validate_off_dates(self, value):
        from store.utils import get_today_kst
        for od in value :
            print(type(od['off_dt']))
            if parse_date(od['off_dt']) < get_today_kst():
                raise serializers.ValidationError("과거 날짜는 휴무일로 등록할 수 없습니다.")
        return value

    def validate_image_file(self, value):  # ← 추가
        if value is None:
            return value
        ext = value.name.rsplit('.', 1)[-1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise serializers.ValidationError("jpg, png, webp 형식만 업로드 가능합니다.")
        if value.size > MAX_IMG_SIZE:
            raise serializers.ValidationError("이미지 크기는 5MB 이하여야 합니다.")
        return value

    def update(self, instance, validated_data):
        working_times = validated_data.pop('working_times', None)
        off_dates = validated_data.pop('off_dates', None)
        image_file = validated_data.pop('image_file', None)

        if image_file is not None:
            user = self.context['request'].user
            image = _save_store_image(image_file, user)
            instance.store_img_id = image

        # Store 기본 필드 업데이트
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # 운영시간 전달 시 전체 교체(upsert)
        if working_times is not None:
            start_time = working_times.get('start_time')
            end_time = working_times.get('end_time')
            end_day_offset = working_times.get('end_day_offset', 0)  # ← 추가

            if start_time is None or end_time is None:
                pass
            else:
                instance.storeworkingtime_set.all().delete()
                new_working_times = [
                    StoreWorkingTime(
                        store_id=instance,
                        working_day=f'D{i:02d}',
                        start_time=start_time,
                        end_time=end_time,
                        end_day_offset=end_day_offset,  # ← 추가
                    ) for i in range(1, 8)
                ]
                StoreWorkingTime.objects.bulk_create(new_working_times)

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
    store_lat = serializers.FloatField()
    store_long = serializers.FloatField()
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
                'end_day_offset': getattr(wt, 'end_day_offset', 0),
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

