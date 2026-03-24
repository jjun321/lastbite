from django.db import models
from user.models.user import User

class GroupCode(models.Model):
    group_code = models.TextField(db_comment="그룹코드", db_column='group_code', primary_key=True, max_length=10)
    group_code_nm = models.TextField(db_comment="그룹코드 이름", db_column='group_code_nm', null=True,max_length=10)
    reg_dt = models.DateTimeField(db_comment="등록 일시", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "group_code"
        db_table_comment = '그룹코드'



class CommonCode(models.Model):
    common_code = models.TextField(db_comment="공통코드", db_column='group_code', primary_key=True, max_length=20)
    group_code_nm = models.ForeignKey(GroupCode,on_delete=models.CASCADE ,db_comment="그룹코드 이름", db_column='group_code_nm', max_length=10)
    code_nm = models.TextField(db_comment="공통코드 이름", db_column='code_nm', max_length=50)
    reg_dt = models.DateTimeField(db_comment="등록 일시", db_column='reg_dt', auto_now_add=True)

    class Meta:
        db_table = "common_code"
        db_table_comment = '공통코드'