from django.db import models
from user.models.user import User

class Image(models.Model):
    img_id = models.BigAutoField(db_comment="이미지 ID", db_column='img_id', primary_key=True)
    user_id = models.ForeignKey(User,on_delete=models.CASCADE,db_comment="업로드 유저", db_column='user_id')
    img_name = models.CharField(db_comment="이미지 이름", db_column="img_name", max_length=200)
    img_url = models.CharField(db_comment="이미지 URL", db_column="img_url", max_length=255)
    img_path = models.CharField(db_comment="이미지 경로", db_column="img_path", max_length=300)
    img_uuid_name = models.CharField(db_comment= "UUID 이름", db_column="img_uuid_name", max_length=255)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "image"
        db_table_comment = '이미지 테이블'
