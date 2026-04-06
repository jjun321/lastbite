from django.shortcuts import render

import math
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


from store.models.store import Store
from product.models.product import Product
from store.serializers import StoreListSerializer, StoreDetailSerializer, StoreWorkingTimeSerializer
from store.utils import haversine_km

DEFAULT_RADIUS_KM = 3
MAX_RADIUS_KM = 10
MAX_PAGE_SIZE = 50


def api_response(success, message, data=None):
    res = {'success': success, 'message': message}
    if data is not None:
        res['data'] = data
    return res


class StoreListView(APIView):
    #GET /stores/
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            lat = float(request.query_params['lat']) if 'lat' in request.query_params else None
            lon = float(request.query_params['lon']) if 'lon' in request.query_params else None
        except ValueError:
            return Response(api_response(False, "lat/lon 값이 올바르지 않습니다."), status=status.HTTP_400_BAD_REQUEST)

        try:
            radius = int(request.query_params.get('radius', DEFAULT_RADIUS_KM))
        except ValueError:
            return Response(api_response(False, "radius 값이 올바르지 않습니다."), status=status.HTTP_400_BAD_REQUEST)

        if not (1 <= radius <= MAX_RADIUS_KM):
            return Response(api_response(False, "반경 값은 1~10km 사이여야 합니다."), status=status.HTTP_400_BAD_REQUEST)

        try:
            page = max(0, int(request.query_params.get('page', 0)))
            size = min(int(request.query_params.get('size', 20)), MAX_PAGE_SIZE)
        except ValueError:
            return Response(api_response(False, "page/size 값이 올바르지 않습니다."), status=status.HTTP_400_BAD_REQUEST)

        # 기본 쿼리
        qs = Store.objects.filter(is_deleted=False).prefetch_related(
            'storeworkingtime_set', 'offdate_set', 'product_set'
        )

        # 위치 기반 필터
        if lat is not None and lon is not None:
            # 1차: 바운딩 박스로 DB 범위 축소
            lat_delta = radius / 111.0
            cos_lat = math.cos(math.radians(lat)) or 1
            lon_delta = radius / (111.0 * cos_lat)

            qs = qs.filter(
                store_lat__gte=lat - lat_delta,
                store_lat__lte=lat + lat_delta,
                store_lon__gte=lon - lon_delta,
                store_lon__lte=lon + lon_delta,
            )

            # 2차: Haversine 정밀 필터 + 거리순 정렬
            with_dist = []
            for store in qs:
                if store.store_lat is None or store.store_lon is None:
                    continue
                dist = haversine_km(lat, lon, float(store.store_lat), store.store_lon)
                if dist <= radius:
                    with_dist.append((dist, store))
            with_dist.sort(key=lambda x: x[0])

            total = len(with_dist)
            paged = [s for _, s in with_dist[page * size:(page + 1) * size]]
            serializer = StoreListSerializer(paged, many=True, context={'ref_lat': lat, 'ref_lon': lon})

        else:
            # 좌표 없으면 전체 조회
            total = qs.count()
            paged_qs = qs.order_by('-reg_dt')[page * size:(page + 1) * size]
            serializer = StoreListSerializer(paged_qs, many=True, context={'ref_lat': None, 'ref_lon': None})

        return Response(api_response(True, "성공", {
            'total': total,
            'page': page,
            'size': size,
            'stores': serializer.data,
        }), status=status.HTTP_200_OK)


class StoreDetailView(APIView):
    #GET /stores/{store_id}/"""
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        try:
            store = Store.objects.prefetch_related(
                'storeworkingtime_set', 'offdate_set'
            ).get(pk=store_id, is_deleted=False)
        except Store.DoesNotExist:
            return Response(api_response(False, "RES_001"), status=status.HTTP_404_NOT_FOUND)

        serializer = StoreDetailSerializer(store)
        return Response(api_response(True, "성공", serializer.data), status=status.HTTP_200_OK)


class StoreHoursView(APIView):
    #GET /stores/{store_id}/hours/
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        try:
            store = Store.objects.get(pk=store_id, is_deleted=False)
        except Store.DoesNotExist:
            return Response(api_response(False, "RES_001"), status=status.HTTP_404_NOT_FOUND)

        hours = store.storeworkingtime_set.all().order_by('working_day')
        serializer = StoreWorkingTimeSerializer(hours, many=True)
        return Response(api_response(True, "성공", serializer.data), status=status.HTTP_200_OK)
