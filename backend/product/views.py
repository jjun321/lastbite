from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from store.models.store import Store
from product.models.product import Product
from product.serializers import ProductListSerializer

MAX_PAGE_SIZE = 50


def api_response(success, message, data=None):
    res = {'success': success, 'message': message}
    if data is not None:
        res['data'] = data
    return res


class StoreProductListView(APIView):
    #GET /stores/{store_id}/products/
    permission_classes = [AllowAny]

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

        total = qs.count()
        paged = qs[page * size:(page + 1) * size]

        serializer = ProductListSerializer(paged, many=True)
        return Response(api_response(True, "성공", {
            'total': total,
            'page': page,
            'size': size,
            'products': serializer.data,
        }), status=status.HTTP_200_OK)