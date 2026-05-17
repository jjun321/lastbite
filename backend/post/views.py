import uuid
import os
import math
from django.conf import settings
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.views import APIView

from common.response import success_response, error_response
from image.models.image import Image
from store.models.store import Store
from post.models.post import Post
from post.serializers import PostResponseSerializer

from store.utils import haversine_km

ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
MAX_SIZE_BYTES = 5 * 1024 * 1024  # 5MB
MAX_PAGE_SIZE = 50
DEFAULT_RADIUS_KM = 3
MAX_RADIUS_KM = 10

def get_post_or_404(post_id):
    # 삭제되지 않은 제보 단건 조회 헬퍼
    try:
        return Post.objects.select_related(
            'user_id', 'img_id', 'store_id'
        ).get(post_id=post_id, is_deleted=False)
    except Post.DoesNotExist:
        return None


def upload_image(image_file, user) -> Image:
    # 이미지 파일 저장 후 Image 반환
    ext = image_file.name.rsplit('.', 1)[-1].lower()
    uuid_name = f"{uuid.uuid4()}.{ext}"
    save_dir = os.path.join(settings.MEDIA_ROOT, 'posts')
    os.makedirs(save_dir, exist_ok=True)

    with open(os.path.join(save_dir, uuid_name), 'wb+') as f:
        for chunk in image_file.chunks():
            f.write(chunk)

    return Image.objects.create(
        user_id=user,
        img_name=image_file.name,
        img_url=f"{settings.MEDIA_URL}posts/{uuid_name}",
        img_path=f"/uploads/posts/{uuid_name}",
        img_uuid_name=uuid_name,
    )


class PostListView(APIView):
    # GET  /posts/ — 제보 목록 조회
    # POST /posts/ — 제보 글 작성
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        try:
            lat = float(request.query_params['lat']) if 'lat' in request.query_params else None
            long = float(request.query_params['long']) if 'long' in request.query_params else None
        except ValueError:
            return error_response(message= "lat/long 값이 올바르지 않습니다.")

        try:
            radius = int(request.query_params.get('radius', DEFAULT_RADIUS_KM))
            #radius = radius / 1000.0  # km 단위로 변환
        except ValueError:
            return error_response(message="radius 값이 올바르지 않습니다.")

        if not (0.1 <= radius <= MAX_RADIUS_KM):
            return error_response(message="반경 값은 1~10km 사이여야 합니다.")
        try:
            page = max(0, int(request.query_params.get('page', 0)))
            size = min(int(request.query_params.get('size', 20)), MAX_PAGE_SIZE)
        except ValueError:
            return error_response(message="page/size 값이 올바르지 않습니다.")
        try:
            store_id = int(request.query_params.get('store_id')) if 'store_id' in request.query_params else None
        except ValueError:
            return error_response(message="store_id 값이 올바르지 않습니다.")
        try:
            product_id = int(request.query_params.get('product_id')) \
                if 'product_id' in request.query_params else None
        except ValueError:
            return error_response(message="product_id 값이 올바르지 않습니다.")

        # sort 파라미터 파싱 (최신순, 주문한 상품)
        sort = request.query_params.get('sort', 'latest')  # latest | ordered
        qs = Post.objects.filter(is_deleted=False).select_related(
            'user_id', 'img_id', 'store_id', 'product_id'
        )

        if store_id is not None:
            qs = qs.filter(store_id=store_id)
        if product_id is not None:
            qs = qs.filter(product_id=product_id)

        if sort == 'ordered':
            from order.models.orderProdList import OrderProdList
            ordered_product_ids = list(
                OrderProdList.objects
                .filter(
                    order_id__user_id=request.user,
                    order_id__order_status='S03',
                )
                .values_list('product_id_id', flat=True)
                .distinct()
            )
            qs = qs.filter(product_id__in=ordered_product_ids)

        if lat is not None and long is not None:
            # 1차: 바운딩 박스로 DB 범위 축소
            lat_delta = radius / 111.0
            cos_lat = math.cos(math.radians(lat)) or 1
            lon_delta = radius / (111.0 * cos_lat)

            qs = qs.filter(
                post_lat__gte=lat - lat_delta,
                post_lat__lte=lat + lat_delta,
                post_long__gte=long - lon_delta,
                post_long__lte=long + lon_delta,
            )

            # 2차: Haversine 정밀 필터 + 거리순 정렬
            with_dist = []
            for post in qs:
                if post.post_lat is None or post.post_long is None:
                    continue
                dist = haversine_km(lat, long, float(post.post_lat), float(post.post_long))
                if dist <= radius:
                    with_dist.append((dist, post))
            with_dist.sort(key=lambda x: x[0])

            total = len(with_dist)
            paged = [s for _, s in with_dist[page * size:(page + 1) * size]]
            serializer = PostResponseSerializer(paged, many=True, context={'ref_lat': lat, 'ref_long': long})

        else:
            # 좌표 없으면 전체 조회
            total = qs.count()
            paged_qs = qs.order_by('-reg_dt')[page * size:(page + 1) * size]
            serializer = PostResponseSerializer(paged_qs, many=True, context={'ref_lat': None, 'ref_long': None})

        return success_response(data={
            'total': total,
            'page': page,
            'size': size,
            'posts': serializer.data,
        })

    def post(self, request):
        # 필수 이름 정보 확인
        post_name = request.data.get('post_name')
        if post_name is None :
            return error_response(message="제보 이름을 입력해주세요.")

        # 위치 확인 (optional)
        post_lat = request.data.get('post_lat')
        post_long = request.data.get('post_long')
        if post_lat and post_long :
            try:
                post_lat = float(post_lat)
                post_long = float(post_long)
            except ValueError:
                return error_response(message="위치 값이 올바르지 않습니다.")

        # 매장 확인 (optional)
        store = None
        store_id = request.data.get('store_id')
        if store_id:
            try:
                store = Store.objects.get(store_id=int(store_id), is_deleted=False)
            except Store.DoesNotExist:
                return error_response(
                    message="존재하지 않는 매장입니다.",
                    status_code=status.HTTP_404_NOT_FOUND,
                )

        product = None
        product_id_param = request.data.get('product_id')
        if product_id_param:
            try:
                from product.models.product import Product
                product = Product.objects.get(
                    product_id=int(product_id_param),
                    is_deleted=False,
                )
            except Product.DoesNotExist:
                return error_response(
                    message="존재하지 않는 상품입니다.",
                    status_code=status.HTTP_404_NOT_FOUND,
                )

        # 이미지 업로드 처리 (optional)
        image_obj = None
        image_file = request.FILES.get('image_file')
        if image_file:
            ext = image_file.name.rsplit('.', 1)[-1].lower()
            if ext not in ALLOWED_EXTENSIONS:
                return error_response(message="jpg, png, webp 형식만 업로드 가능합니다.")
            if image_file.size > MAX_SIZE_BYTES:
                return error_response(message="이미지 크기는 5MB 이하여야 합니다.")

        with transaction.atomic():
            if image_file:
                image_obj = upload_image(image_file, request.user)

            post = Post.objects.create(
                user_id=request.user,
                img_id=image_obj,
                post_name=post_name,
                content=request.data.get('content'),
                post_lat=post_lat,
                post_long=post_long,
                store_id=store,
                product_id=product,
                is_deleted=False,
            )

        # select_related로 응답용 재조회
        post = Post.objects.select_related('user_id', 'img_id', 'store_id').get(pk=post.pk)
        serializer = PostResponseSerializer(post)
        return success_response(data=serializer.data, status_code=status.HTTP_201_CREATED)


class PostDetailView(APIView):
    #GET    /posts/{post_id}/ — 제보 상세 조회
    #DELETE /posts/{post_id}/ — 제보 삭제 (본인만 가능, is_deleted=True로)
    permission_classes = [IsAuthenticated]

    def get(self, request, post_id):
        post = get_post_or_404(post_id)
        if not post:
            return error_response(
                message="제보를 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        serializer = PostResponseSerializer(post)
        return success_response(data=serializer.data)

    def delete(self, request, post_id):
        post = get_post_or_404(post_id)
        if not post:
            return error_response(
                message="제보를 찾을 수 없습니다.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # 본인 글인지 확인
        if post.user_id_id != request.user.pk:
            return error_response(
                message="삭제 권한이 없습니다.",
                status_code=status.HTTP_403_FORBIDDEN,
            )

        post.is_deleted = True
        post.save(update_fields=['is_deleted'])
        return success_response(data={"post_id": post_id})