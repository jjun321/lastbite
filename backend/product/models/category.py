from django.db import models

class Category(models.Model):
    category_id = models.BigAutoField(db_comment="카테고리 ID", db_column='category_id', primary_key=True)
    category_name = models.CharField(db_comment="카테고리 이름", db_column='category_name', max_length=20)
    is_deleted = models.BooleanField(db_comment="삭제 여부", db_column='is_deleted', default=False)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "category"
        db_table_comment = '카테고리 테이블'