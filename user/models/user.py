from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin, Group,
)
from django.db import models

from user.models.choices import USER_TYPE_CHOICE


class UserManager(BaseUserManager):
    def create_user(self, user_email, password=None, **extra_fields):
        if not user_email:
            raise ValueError("The user_email must be set")

        # ManyToMany 필드 추출 및 기본값 처리
        groups = extra_fields.pop('groups', None)
        if groups is None:
            group, created = Group.objects.get_or_create(name='user')
            groups = [group]

        user_permissions = extra_fields.pop('user_permissions', [])

        user_email = self.normalize_email(user_email)
        user = self.model(user_email=user_email, **extra_fields)

        # 비밀번호 설정
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()

        user.save(using=self._db)  # 저장 먼저

        # ManyToMany 필드 설정은 저장 후에!
        if groups:
            user.groups.set(groups)
        if user_permissions:
            user.user_permissions.set(user_permissions)

        return user

    def create_superuser(self, user_email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if not password:
            raise ValueError("Superuser must have a password.")

        return self.create_user(user_email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    user_id = models.BigAutoField(db_comment="유저 ID", db_column='user_id', primary_key=True)
    profile_img_id = models.IntegerField(db_comment="프로필 이미지 ID", db_column='profile_img_id', null=True)
    user_name = models.CharField(db_comment="유저 이름", db_column="user_name", max_length=20)
    user_phone = models.CharField(db_comment="유저 전화번호", db_column="user_phone", max_length=30)  # 차후 전화번호 인증 정책 필요함
    user_email = models.EmailField(db_comment="유저 이메일", db_column="user_email", max_length=50, unique=True)
    password = models.CharField(db_comment='유저 비밀번호', db_column='password', max_length=255, null=True)
    user_type = models.CharField(db_comment="유저 타입", db_column="user_type", max_length=10, choices=USER_TYPE_CHOICE)
    provider_id = models.CharField(db_comment="소셜 로그인 ID", db_column="provider_id", max_length=255, null=True)
    platform = models.CharField(db_comment="소셜 로그인 플랫폼", db_column="platform", max_length=50, null=True)
    reg_dt = models.DateTimeField(db_comment="생성 일자", db_column='reg_dt', auto_now_add=True)

    is_active = models.BooleanField(db_comment='활성화 여부', default=True)
    is_staff = models.BooleanField(db_comment='스태프 여부', default=False)

    objects = UserManager()
    USERNAME_FIELD = "user_email"
    #keycloak <- 소셜 로그인 지원

    class Meta:
        db_table = "user"
        db_table_comment = '유저 테이블'
