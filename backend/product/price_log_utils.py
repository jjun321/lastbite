"""
product/price_log_utils.py

가격 로그 저장 헬퍼.
점주가 제품을 등록하거나 수정할 때 호출하여 가격 이력을 남김.
"""

from product.models.price_log import PriceLog


def record_price_log(product, owner):
    """
    제품 등록/수정 직후 호출.
    discount_rate는 PriceLog.save() 오버라이드에서 자동 계산됨.

    Args:
        product: Product 인스턴스 (저장 완료 상태)
        owner:   점주 User 인스턴스
    """
    PriceLog.objects.create(
        product_id=product,
        store_id=product.store_id,
        owner_id=owner,
        product_dis_price=product.product_dis_price,
        product_ori_price=product.product_ori_price,
        # discount_rate는 PriceLog.save()에서 자동 계산
    )
