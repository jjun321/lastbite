"""
-가게 관리
  POST   /owner/stores/                  가게 최초 등록
  GET    /owner/stores/me/               내 가게 정보 조회
  PATCH  /owner/stores/<store_id>/       가게 정보 수정
  DELETE /owner/stores/<store_id>/       가게 삭제 (soft delete)

-휴무일 관리
  GET    /owner/stores/<store_id>/off-dates/              휴무일 목록 조회
  POST   /owner/stores/<store_id>/off-dates/              휴무일 등록
  DELETE /owner/stores/<store_id>/off-dates/<date_id>/    휴무일 삭제

-운영시간 관리
  GET    /owner/stores/<store_id>/working-times/                          운영시간 조회
  POST   /owner/stores/<store_id>/working-times/                          운영시간 단건 추가
  PATCH  /owner/stores/<store_id>/working-times/<working_time_id>/        운영시간 단건 수정
  DELETE /owner/stores/<store_id>/working-times/<working_time_id>/        운영시간 단건 삭제
"""

from django.db import transaction
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, JSONParser
from rest_framework import status

from common.response import success_response, error_response, extract_first_error
from store.models.store import Store
from store.models.off_date import OffDate
from store.models.store_working_time import StoreWorkingTime
from store.serializers import (
    OwnerStoreCreateSerializer,
    OwnerStoreUpdateSerializer,
    OwnerStoreDetailSerializer,
    OffDateCreateSerializer,
    StoreWorkingTimeSerializer,
)


#  공통 헬퍼
def get_owner_store(user, store_id):
    #요청 유저 소유 + 미삭제 매장 반환. 없으면 None.
    try:
        return Store.objects.prefetch_related(
            'storeworkingtime_set', 'offdate_set'
        ).get(pk=store_id, user_id=user, is_deleted=False)
    except Store.DoesNotExist:
        return None


def check_owner_type(user):
    #점주 타입인지 확인. 아니면 error_response 반환.
    if user.user_type != 'U02':
        return error_response("점주 전용 기능입니다.", status_code=status.HTTP_403_FORBIDDEN)
    return None



#  가게 등록 / 내 가게 조회
class OwnerStoreView(APIView):
    """
    POST /owner/stores/   — 가게 최초 등록
    GET  /owner/stores/me/ 는 별도 뷰(OwnerStoreMeView) 사용
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        error = check_owner_type(request.user)
        if error:
            return error

        # 이미 가게를 보유한 경우 중복 등록 차단
        if Store.objects.filter(user_id=request.user, is_deleted=False).exists():
            return error_response("이미 등록된 가게가 있습니다.", status_code=status.HTTP_400_BAD_REQUEST)

        serializer = OwnerStoreCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(extract_first_error(serializer.errors))

        with transaction.atomic():
            store = serializer.save(user_id=request.user)

        return success_response(
            data={
                'store_id': store.store_id,
                'store_name': store.store_name,
            },
            message="가게가 등록되었습니다.",
            status_code=status.HTTP_201_CREATED,
        )


class OwnerStoreMeView(APIView):
    """GET /owner/stores/me/ — 내 가게 정보 조회"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        error = check_owner_type(request.user)
        if error:
            return error

        try:
            store = Store.objects.prefetch_related(
                'storeworkingtime_set', 'offdate_set'
            ).get(user_id=request.user, is_deleted=False)
        except Store.DoesNotExist:
            return error_response("등록된 가게가 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OwnerStoreDetailSerializer(store)
        return success_response(data=serializer.data)


#  가게 수정 / 삭제
class OwnerStoreManageView(APIView):
    """
    PATCH  /owner/stores/<store_id>/ — 가게 정보 수정
    DELETE /owner/stores/<store_id>/ — 가게 삭제(soft)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OwnerStoreUpdateSerializer(store, data=request.data, partial=True)
        if not serializer.is_valid():
            return error_response(extract_first_error(serializer.errors))

        with transaction.atomic():
            serializer.save()

        # 수정 후 최신 정보 반환
        store.refresh_from_db()
        detail = OwnerStoreDetailSerializer(
            Store.objects.prefetch_related(
                'storeworkingtime_set', 'offdate_set'
            ).get(pk=store_id)
        )
        return success_response(data=detail.data, message="가게 정보가 수정되었습니다.")

    def delete(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        store.is_deleted = True
        store.save(update_fields=['is_deleted'])
        return success_response(message="가게가 삭제되었습니다.")


#  휴무일 관리
class OwnerOffDateView(APIView):
    """
    GET  /owner/stores/<store_id>/off-dates/  — 휴무일 목록
    POST /owner/stores/<store_id>/off-dates/  — 휴무일 등록
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        from store.utils import get_today_kst
        today = get_today_kst()
        off_dates = store.offdate_set.filter(off_dt__gte=today).order_by('off_dt')
        data = [
            {
                'closed_date_id': od.closed_date_id,
                'off_dt': od.off_dt.strftime('%Y-%m-%d'),
                'off_desc': od.off_desc,
            }
            for od in off_dates
        ]
        return success_response(data=data)

    def post(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = OffDateCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return error_response(extract_first_error(serializer.errors))

        off_dt = serializer.validated_data['off_dt']
        # 동일 날짜 중복 등록 방지
        if store.offdate_set.filter(off_dt=off_dt).exists():
            return error_response("해당 날짜는 이미 휴무일로 등록되어 있습니다.")

        od = OffDate.objects.create(
            store_id=store,
            user_id=request.user,
            off_dt=off_dt,
            off_desc=serializer.validated_data.get('off_desc'),
        )
        return success_response(
            data={
                'closed_date_id': od.closed_date_id,
                'off_dt': od.off_dt.strftime('%Y-%m-%d'),
                'off_desc': od.off_desc,
            },
            message="휴무일이 등록되었습니다.",
            status_code=status.HTTP_201_CREATED,
        )


class OwnerOffDateDeleteView(APIView):
    """DELETE /owner/stores/<store_id>/off-dates/<date_id>/ — 휴무일 삭제"""
    permission_classes = [IsAuthenticated]

    def delete(self, request, store_id, date_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        try:
            od = store.offdate_set.get(pk=date_id)
        except OffDate.DoesNotExist:
            return error_response("해당 휴무일을 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        od.delete()
        return success_response(message="휴무일이 삭제되었습니다.")


#  운영시간 관리
class OwnerWorkingTimeView(APIView):
    """
    GET  /owner/stores/<store_id>/working-times/  — 운영시간 목록
    POST /owner/stores/<store_id>/working-times/  — 운영시간 단건 추가
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        wts = store.storeworkingtime_set.all().order_by('working_day')
        serializer = StoreWorkingTimeSerializer(wts, many=True)
        return success_response(data=serializer.data)

    def post(self, request, store_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store = get_owner_store(request.user, store_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        working_day = request.data.get('working_day')
        start_time = request.data.get('start_time')
        end_time = request.data.get('end_time')

        valid_days = {f'D{i:02d}' for i in range(1, 8)}
        if working_day not in valid_days:
            return error_response("working_day는 D01~D07 중 하나여야 합니다.")

        # 동일 요일 중복 등록 방지
        if store.storeworkingtime_set.filter(working_day=working_day).exists():
            return error_response("해당 요일은 이미 운영시간이 등록되어 있습니다. 수정 API를 사용해주세요.")

        try:
            wt = StoreWorkingTime.objects.create(
                store_id=store,
                working_day=working_day,
                start_time=start_time,
                end_time=end_time,
            )
        except Exception:
            return error_response("시간 형식이 올바르지 않습니다. (HH:MM)")

        return success_response(
            data={
                'working_time_id': wt.working_time_id,
                'working_day': wt.working_day,
                'start_time': wt.start_time.strftime('%H:%M'),
                'end_time': wt.end_time.strftime('%H:%M'),
            },
            message="운영시간이 추가되었습니다.",
            status_code=status.HTTP_201_CREATED,
        )


class OwnerWorkingTimeManageView(APIView):
    """
    PATCH  /owner/stores/<store_id>/working-times/<working_time_id>/ — 운영시간 수정
    DELETE /owner/stores/<store_id>/working-times/<working_time_id>/ — 운영시간 삭제
    """
    permission_classes = [IsAuthenticated]

    def _get_working_time(self, user, store_id, working_time_id):
        store = get_owner_store(user, store_id)
        if store is None:
            return None, None
        try:
            wt = store.storeworkingtime_set.get(pk=working_time_id)
            return store, wt
        except StoreWorkingTime.DoesNotExist:
            return store, None

    def patch(self, request, store_id, working_time_id):
        error = check_owner_type(request.user)
        if error:
            return error

        store, wt = self._get_working_time(request.user, store_id, working_time_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)
        if wt is None:
            return error_response("운영시간 정보를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        start_time = request.data.get('start_time', wt.start_time)
        end_time = request.data.get('end_time', wt.end_time)

        try:
            wt.start_time = start_time
            wt.end_time = end_time
            wt.save(update_fields=['start_time', 'end_time'])
        except Exception:
            return error_response("시간 형식이 올바르지 않습니다. (HH:MM)")

        return success_response(
            data={
                'working_time_id': wt.working_time_id,
                'working_day': wt.working_day,
                'start_time': wt.start_time.strftime('%H:%M'),
                'end_time': wt.end_time.strftime('%H:%M'),
            },
            message="운영시간이 수정되었습니다.",
        )

    def delete(self, request, store_id, working_time_id):
        err = check_owner_type(request.user)
        if err:
            return err

        store, wt = self._get_working_time(request.user, store_id, working_time_id)
        if store is None:
            return error_response("가게를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)
        if wt is None:
            return error_response("운영시간 정보를 찾을 수 없습니다.", status_code=status.HTTP_404_NOT_FOUND)

        wt.delete()
        return success_response(message="운영시간이 삭제되었습니다.")
