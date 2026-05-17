from django.db import models
from user.models.user import User
from image.models.image import Image
from store.models.store import Store


class Post(models.Model):
    post_id = models.BigAutoField(
        db_comment="제보 ID", db_column='post_id', primary_key=True
    )
    post_name = models.CharField(
        db_comment="제보 이름", db_column='post_name',
        max_length=100, default='할인'
    )
    user_id = models.ForeignKey(
        User, on_delete=models.CASCADE,
        db_comment="소비자 ID", db_column='user_id'
    )
    img_id = models.ForeignKey(
        Image, on_delete=models.SET_NULL,
        db_comment="제보 이미지 ID", db_column='post_img_id',
        null=True, blank=True
    )
    content = models.TextField(
        db_comment="제보 내용", db_column='content',
        null=True, blank=True
    )
    post_long = models.DecimalField(
        db_comment="제보 위치 경도", db_column='post_long',
        max_digits=11, decimal_places=7, null=True, blank=True
    )
    post_lat = models.DecimalField(
        db_comment="제보 위치 위도", db_column='post_lat',
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    is_deleted = models.BooleanField(
        db_comment="삭제 여부", db_column='is_deleted', default=False
    )
    reg_dt = models.DateTimeField(
        db_comment="제보 날짜", db_column='reg_dt', auto_now_add=True
    )
    store_id = models.ForeignKey(
        Store, on_delete=models.SET_NULL,
        db_comment="매장 ID", db_column='store_id',
        null=True, blank=True
    )
    product_id = models.ForeignKey(
        'product.Product',
        on_delete=models.SET_NULL,
        db_comment="연관 상품 ID",
        db_column='product_id',
        null=True, blank=True,
        related_name='posts',
    )

    class Meta:
        db_table = "post"
        db_table_comment = '제보 테이블'
        ordering = ['-reg_dt']