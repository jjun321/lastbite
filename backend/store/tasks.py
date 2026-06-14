import logging

from celery import shared_task

from store.models.store import Store
from store.utils import auto_soldout_closed_stores

logger = logging.getLogger(__name__)


@shared_task(name="store.tasks.auto_soldout_all_closed_stores")
def auto_soldout_all_closed_stores() -> int:
    """
    [자동 종료 스케줄러]
    전체 매장을 대상으로 현재 영업시간이 아닌(휴무일 포함) 매장을 찾아
    해당 매장의 판매중 상품(product_count > 0)을 일괄 품절(0) 처리한다.

    - django-celery-beat의 PeriodicTask로 주기 실행 (예: 매 5~10분)
    - 기존 lazy 방식(auto_soldout_if_closed / auto_soldout_closed_stores)을
      뷰 호출 시점이 아닌, 스케줄러가 주기적으로 호출하도록 전환.
    - 이미 product_count=0인 상품은 UPDATE 대상에서 제외되므로
      반복 실행되어도 변경분이 없으면 즉시 종료된다.
    - 재고 자동 복구는 하지 않음 (영업 재개 시 점주가 직접 재등록/수정).

    Returns:
        int: 이번 실행에서 품절 처리된 상품 row 수
    """
    stores = list(Store.objects.filter(is_deleted=False, is_closed=False))

    if not stores:
        logger.info("[auto_soldout] 대상 매장 없음")
        return 0

    updated = auto_soldout_closed_stores(stores)

    if updated:
        logger.info("[auto_soldout] 영업 종료 매장 상품 %d건 품절 처리 완료", updated)
    else:
        logger.debug("[auto_soldout] 품절 처리 대상 없음 (모든 매장 영업 중이거나 이미 처리됨)")

    return updated
