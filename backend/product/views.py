import math
import json
import urllib.request
import urllib.error
from django.conf import settings

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny

from common.response import success_response, error_response
from store.models.store import Store
from store.utils import haversine_km
from product.models.product import Product
from product.serializers import ProductListSerializer, CategoryListSerializer, ProductSearchSerializer, HotDealSerializer
from product.models.category import Category
from collections import Counter
from order.models.orderProdList import OrderProdList

MAX_PAGE_SIZE = 50
DEFAULT_RADIUS  = 3
MAX_RADIUS      = 10

def _call_ml_anomaly(store_id: int, discount_rate: int) -> dict | None:
    """ML 서버 이상치 탐지 단건 호출 헬퍼"""
    url     = f"{settings.ML_SERVER_URL}/anomaly/detect/"
    payload = json.dumps({"store_id": store_id, "discount_rate": discount_rate}).encode()
    req     = urllib.request.Request(
        url, data=payload,
        headers={
            "Content-Type":       "application/json",
            "X-Internal-API-Key": settings.ML_INTERNAL_API_KEY,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read())
    except Exception:
        return None


def _get_user_preferred_categories(user) -> set:
    """
    유저의 S03 완료 주문에서 구매한 category_id 집합 반환.
    ProductSearch / HotDeal 양쪽에서 '이미 주문한 카테고리' 상단 노출에 활용.
    """
    ordered_product_ids = list(
        OrderProdList.objects
        .filter(order_id__user_id=user, order_id__order_status='S03')
        .values_list('product_id_id', flat=True)
        .distinct()
    )
    if not ordered_product_ids:
        return set()

    category_ids = set(
        Product.objects
        .filter(product_id__in=ordered_product_ids, is_deleted=False)
        .values_list('category_id_id', flat=True)
    )
    return category_ids


def _build_bounding_box_filter(lat, lon, radius):
    """바운딩 박스 필터 딕셔너리 반환 (store FK 경유 쿼리용)."""
    lat_delta = radius / 111.0
    cos_lat   = math.cos(math.radians(lat)) or 1e-9
    lon_delta = radius / (111.0 * cos_lat)
    return {
        'store_id__store_lat__gte':  lat - lat_delta,
        'store_id__store_lat__lte':  lat + lat_delta,
        'store_id__store_long__gte': lon - lon_delta,
        'store_id__store_long__lte': lon + lon_delta,
    }

def api_response(success, message, data=None):
    res = {'success': success, 'message': message}
    if data is not None:
        res['data'] = data
    return res

#store의 뷰에 두면 store 가 product의 각종 상세 필드 알아야함. 시리얼라이저의 로직도 product의 필드에 의존하기에 product에 둠
class StoreProductListView(APIView):
    #GET /stores/{store_id}/products/
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        # 매장 존재 확인
        try:
            Store.objects.get(pk=store_id, is_deleted=False)
        except Store.DoesNotExist:
            return Response(api_response(False, "RES_001"), status=status.HTTP_404_NOT_FOUND)

        try:
            page = max(0, int(request.query_params.get('page', 0)))
            size = min(int(request.query_params.get('size', 20)), MAX_PAGE_SIZE)
        except ValueError:
            return Response(api_response(False, "page/size 값이 올바르지 않습니다."), status=status.HTTP_400_BAD_REQUEST)

        category_id = request.query_params.get('category_id')
        sort = request.query_params.get('sort', 'default')

        qs = (
            Product.objects
            .filter(store_id=store_id, is_deleted=False)
            .select_related('category_id')
            .prefetch_related('productimg_set__img_id')
            .order_by('product_dis_price')
        )

        if category_id:
            try:
                qs = qs.filter(category_id=int(category_id))
            except ValueError:
                return Response(api_response(False, "category_id 값이 올바르지 않습니다."), status=status.HTTP_400_BAD_REQUEST)

        # ── 정렬 처리 ─────────────────────────────────────────────────────────
        if sort == 'price_asc':
            # 최저가순
            qs = qs.order_by('product_dis_price')

        elif sort == 'latest':
            # 최신순
            qs = qs.order_by('-reg_dt')

        elif sort == 'hotdeal':
            # 핫딜순 — 할인율 내림차순 (계산값이므로 Python 정렬)
            products = list(qs)
            products.sort(
                key=lambda p: (
                    int((1 - p.product_dis_price / p.product_ori_price) * 100)
                    if p.product_ori_price else 0
                ),
                reverse=True,
            )
            total  = len(products)
            paged  = products[page * size:(page + 1) * size]
            return Response(api_response(True, "성공", {
                'total':    total,
                'page':     page,
                'size':     size,
                'sort':     sort,
                'products': ProductListSerializer(paged, many=True).data,
            }), status=status.HTTP_200_OK)

        elif sort == 'ordered':
            # ── 주문이력 기반 상단 노출 ────────────────────────────────────────
            # 1. 현재 유저의 S03 완료 주문에서 상품별 주문 횟수 집계
            order_counts = Counter(
                OrderProdList.objects
                .filter(
                    order_id__user_id=request.user,
                    order_id__order_status='S03',
                    product_id__store_id=store_id,
                )
                .values_list('product_id_id', flat=True)
            )

            if not order_counts:
                # 주문이력 없으면 등록순(default) 적용
                qs = qs.order_by('product_id')
            else:
                # 2. 최다 주문 횟수와 같은 상품 ID 집합 → 상단 노출 대상
                max_count   = max(order_counts.values())
                top_ids     = {pid for pid, cnt in order_counts.items() if cnt == max_count}

                products    = list(qs)
                # 상위 주문 상품 먼저, 나머지는 등록순
                products.sort(key=lambda p: (0 if p.product_id in top_ids else 1, p.product_id))

                total  = len(products)
                paged  = products[page * size:(page + 1) * size]
                return Response(api_response(True, "성공", {
                    'total':    total,
                    'page':     page,
                    'size':     size,
                    'sort':     sort,
                    'products': ProductListSerializer(paged, many=True).data,
                }), status=status.HTTP_200_OK)

        else:
            # default — 등록순
            qs = qs.order_by('product_id')

        total = qs.count()
        paged = qs[page * size:(page + 1) * size]

        serializer = ProductListSerializer(paged, many=True)
        return Response(api_response(True, "성공", {
            'total': total,
            'page': page,
            'size': size,
            'sort': sort,
            'products': serializer.data,
        }), status=status.HTTP_200_OK)

class CategoryListView(APIView) :
    permission_classes = [IsAuthenticated]
    # GET /stores/categories/
    def get(self, request):
        qs = Category.objects.filter(is_deleted=False)
        serializer = CategoryListSerializer(qs, many=True)
        return Response(api_response(True, "성공", serializer.data), status=status.HTTP_200_OK)

class CategoryDetailView(APIView) :
    permission_classes = [IsAuthenticated]
    # GET /stores/categories/{category_id}
    def get(self, request, category_id):
        try:
            qs = Category.objects.filter(category_id=category_id, is_deleted=False)
            serializer = CategoryListSerializer(qs, many=True)
            return Response(api_response(True, "성공", serializer.data), status=status.HTTP_200_OK)
        except Category.DoesNotExist:
            return Response(api_response(False, "RES_001"), status=status.HTTP_404_NOT_FOUND)


class ProductSearchView(APIView):
    """
    GET /products/search/

    동작:
      1. 키워드/카테고리/위치 필터 적용
      2. 유저 주문 완료(S03) 카테고리 집합 조회 → is_preferred 플래그
      3. ML 이상치 탐지 → is_special 플래그
      4. 정렬: is_preferred(주문이력 카테고리) 우선 → is_special 우선 → 거리/할인율순
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        keyword     = request.query_params.get('keyword', '').strip()
        category_id = request.query_params.get('category_id')

        try:
            lat    = float(request.query_params['lat']) if 'lat' in request.query_params else None
            lon    = float(request.query_params['lon']) if 'lon' in request.query_params else None
            radius = int(request.query_params.get('radius', DEFAULT_RADIUS))
            page   = max(0, int(request.query_params.get('page', 0)))
            size   = min(int(request.query_params.get('size', 20)), MAX_PAGE_SIZE)
        except ValueError:
            return error_response("파라미터 값이 올바르지 않습니다.")

        if radius < 1 or radius > MAX_RADIUS:
            return error_response("반경 값은 1~10km 사이여야 합니다.")

        # ── 1. 기본 쿼리 ──────────────────────────────────────────────────────
        qs = (
            Product.objects
            .filter(
                is_deleted=False,
                product_count__gt=0,
                store_id__is_deleted=False,
                store_id__is_closed=False,
            )
            .select_related('store_id', 'category_id')
            .prefetch_related('productimg_set__img_id')
        )

        if keyword:
            qs = qs.filter(product_name__icontains=keyword)

        if category_id:
            try:
                qs = qs.filter(category_id=int(category_id))
            except ValueError:
                return error_response("category_id 값이 올바르지 않습니다.")

        # ── 2. 위치 필터 ──────────────────────────────────────────────────────
        if lat is not None and lon is not None:
            qs = qs.filter(**_build_bounding_box_filter(lat, lon, radius))
            with_dist = []
            for p in qs:
                s = p.store_id
                if s.store_lat is None or s.store_long is None:
                    continue
                dist = haversine_km(lat, lon, float(s.store_lat), float(s.store_long))
                if dist <= radius:
                    with_dist.append((dist, p))
            products_list = [p for _, p in with_dist]
            context = {'ref_lat': lat, 'ref_lon': lon}
        else:
            products_list = list(qs)
            context = {}

        # ── 3. 유저 주문 카테고리 집합 ────────────────────────────────────────
        preferred_categories = _get_user_preferred_categories(request.user)
        context['preferred_category_ids'] = preferred_categories

        # ── 4. ML 이상치 탐지 (상품별 단건 호출) ─────────────────────────────
        anomaly_map = {}
        for p in products_list:
            if p.product_ori_price and p.product_dis_price:
                rate = int((1 - p.product_dis_price / p.product_ori_price) * 100)
                ml   = _call_ml_anomaly(p.store_id_id, rate)
                anomaly_map[p.pk] = (
                    ml is not None and
                    ml.get('data', {}).get('direction') == 'HIGH'
                )
        context['anomaly_map'] = anomaly_map

        # ── 5. 정렬 ───────────────────────────────────────────────────────────
        # 우선순위: ① is_preferred(주문이력 카테고리) ② is_special(이상치 HIGH) ③ 할인율
        def _sort_key(p):
            cat_id      = p.category_id.category_id if p.category_id else None
            is_preferred = cat_id in preferred_categories if cat_id else False
            is_special   = anomaly_map.get(p.pk, False)
            ori          = p.product_ori_price or 0
            dis          = p.product_dis_price or 0
            rate         = int((1 - dis / ori) * 100) if ori else 0
            return (
                0 if is_preferred else 1,   # 주문이력 카테고리 우선
                0 if is_special   else 1,   # 이상치 HIGH 우선
                -rate,                      # 할인율 높은 순
            )

        products_list.sort(key=_sort_key)

        total = len(products_list)
        paged = products_list[page * size:(page + 1) * size]

        return success_response(data={
            'total':    total,
            'page':     page,
            'size':     size,
            'products': ProductSearchSerializer(paged, many=True, context=context).data,
        })


class HotDealView(APIView):
    """
    GET /products/hotdeal/

    동작:
      1. 반경 내 매장별 할인율 최고 상품 수집
      2. ML 이상치 탐지 → is_special 플래그
      3. 유저 주문 카테고리 → is_preferred 플래그
      4. 정렬: is_preferred 우선 → is_special 우선 → 할인율순
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            lat    = float(request.query_params['lat']) if 'lat' in request.query_params else None
            lon    = float(request.query_params['lon']) if 'lon' in request.query_params else None
            radius = int(request.query_params.get('radius', DEFAULT_RADIUS))
            size   = min(int(request.query_params.get('size', 10)), MAX_PAGE_SIZE)
        except ValueError:
            return error_response("파라미터 값이 올바르지 않습니다.")

        # ── 1. 반경 내 활성 매장 ─────────────────────────────────────────────
        store_qs = Store.objects.filter(is_deleted=False, is_closed=False)

        if lat is not None and lon is not None:
            lat_delta = radius / 111.0
            cos_lat   = math.cos(math.radians(lat)) or 1e-9
            lon_delta = radius / (111.0 * cos_lat)
            store_qs  = store_qs.filter(
                store_lat__gte=lat - lat_delta,
                store_lat__lte=lat + lat_delta,
                store_long__gte=lon - lon_delta,
                store_long__lte=lon + lon_delta,
            )
            stores = [
                s for s in store_qs
                if s.store_lat and s.store_long and
                   haversine_km(lat, lon, float(s.store_lat), float(s.store_long)) <= radius
            ]
        else:
            stores = list(store_qs)

        # ── 2. 매장별 할인율 최고 상품 수집 ─────────────────────────────────
        candidates = []
        for store in stores:
            rep = (
                Product.objects
                .filter(
                    store_id=store,
                    is_deleted=False,
                    product_count__gt=0,
                    product_dis_price__isnull=False,
                    product_ori_price__isnull=False,
                )
                .select_related('category_id')
                .prefetch_related('productimg_set__img_id')
                .first()
            )
            if not rep or not rep.product_ori_price:
                continue

            ori  = rep.product_ori_price
            dis  = rep.product_dis_price
            rate = int((1 - dis / ori) * 100) if ori else 0
            candidates.append({'product': rep, 'store': store, 'discount_rate': rate})

        if not candidates:
            return success_response(data={'total': 0, 'products': []})

        # ── 3. 유저 주문 카테고리 집합 ────────────────────────────────────────
        preferred_categories = _get_user_preferred_categories(request.user)

        # ── 4. ML 이상치 탐지 ─────────────────────────────────────────────────
        results = []
        for c in candidates:
            product       = c['product']
            store         = c['store']
            discount_rate = c['discount_rate']

            ml         = _call_ml_anomaly(store.store_id, discount_rate)
            is_special = (
                ml is not None and
                ml.get('data', {}).get('direction') == 'HIGH'
            )

            cat_id       = product.category_id.category_id if product.category_id else None
            is_preferred = cat_id in preferred_categories if cat_id else False

            img_url = None
            pi      = product.productimg_set.select_related('img_id').first()
            if pi:
                img_url = pi.img_id.img_url

            results.append({
                'product_id':        product.product_id,
                'product_name':      product.product_name,
                'product_ori_price': product.product_ori_price,
                'product_dis_price': product.product_dis_price,
                'discount_rate':     discount_rate,
                'img_url':           img_url,
                'is_special':        is_special,    # 이상치 HIGH → 지도 빨간 마커
                'is_preferred':      is_preferred,  # 주문이력 카테고리 → 상단 노출
                'store_id':          store.store_id,
                'store_name':        store.store_name,
                'store_address':     store.store_address,
                'store_lat':         float(store.store_lat)  if store.store_lat  else None,
                'store_lon':         float(store.store_long) if store.store_long else None,
            })

        # ── 5. 정렬: is_preferred 우선 → is_special 우선 → 할인율순 ───────────
        results.sort(key=lambda r: (
            0 if r['is_preferred'] else 1,
            0 if r['is_special']   else 1,
            -r['discount_rate'],
        ))

        top = results[:size]
        return success_response(data={
            'total':    len(top),
            'products': HotDealSerializer(top, many=True).data,
        })