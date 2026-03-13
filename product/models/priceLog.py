from django.db import models

class PriceLog(models.Model):
    log_id = models.BigAutoField(db_comment="로그 ID", db_column='log_id', primary_key=True)

    # 아직 완성 안됐으므로 외래키는 주석처리
    #market = models.ForeignKey('market.Market', on_delete=models.CASCADE, db_comment="매장 ID", db_column='market_id')
    #user = models.ForeignKey('user.User', on_delete=models.CASCADE, db_comment="점주 ID", db_column='user_id')

    market_id = models.IntegerField(db_comment="매장 ID", db_column='market_id', null=True)
    user_id = models.IntegerField(db_comment="점주 ID", db_column='user_id', null=True)
    product_dis_price = models.IntegerField(db_comment="제품 할인 후 가격", db_column='product_dis_price', null=True)
    product_ori_price = models.IntegerField(db_comment="제품 할인 전 가격", db_column='product_ori_price', null=True)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "price_log"
        db_table_comment = '가격 로그 테이블'