import re
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from user.models.user import User
from user.models.choices import USER_TYPE_CHOICE

# TokenObtainPairSerializer 상속으로 구현한 로그인 시리얼라이저
class LoginSerializer(TokenObtainPairSerializer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['user_email'] = serializers.EmailField()
        self.fields['user_password'] = serializers.CharField()
        if 'username' in self.fields: del self.fields['username']
        if 'password' in self.fields: del self.fields['password']

    def validate(self, attrs):
        attrs[self.username_field] = attrs.get('user_email')
        attrs['password'] = attrs.get('user_password')
        
        data = super().validate(attrs)
        
        # API 명세서 Response 규격에 맞춰 정보 추가
        data['access_token'] = data.pop('access')
        data['refresh_token'] = data.pop('refresh')
        data['user'] = {
            "user_id": self.user.user_id,
            "user_name": self.user.user_name,
            "user_email": self.user.user_email,
            "user_phone": self.user.user_phone,
            "user_type": self.user.user_type
        }
        return data

# 회원가입 유효성 검사하고 유효할 시 유저 생성하는데 사용
class RegisterSerializer(serializers.ModelSerializer):
    password_confirm = serializers.CharField(write_only=True, required=True)
    user_password = serializers.CharField(write_only=True, required=True, min_length=8, max_length=20)
    user_phone = serializers.CharField(required=True, max_length=30)
    user_type = serializers.ChoiceField(choices=USER_TYPE_CHOICE, required=True)

    class Meta:
        model = User
        fields = ['user_name', 'user_email', 'user_phone', 'user_password', 'password_confirm', 'user_type']

    def validate_user_phone(self, value):
        # 전화번호 형식 검사
        if not re.match(r'^\d{3}-\d{4}-\d{4}$', value) or re.match(r'^\d{3}-\d{3}-\d{4}$', value):
            raise serializers.ValidationError("전화번호 형식이 올바르지 않습니다. (예: 123-4567-8901 or 123-456-7890)")
        return value

    def validate_user_password(self, value):
        # 비멀번호 형식 검사, 8~20자, 영문+숫자+특수문자 조합
        regex = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$'
        if not re.match(regex, value):
            raise serializers.ValidationError("비밀번호는 8~20자이며, 영문, 숫자, 특수문자를 모두 포함해야 합니다.")
        return value

    def validate(self, data):
        # 비밀번호 확인
        if data.get('user_password') != data.get('password_confirm'):
            raise serializers.ValidationError({"password_confirm": "비밀번호가 일치하지 않습니다."})
        return data

    def create(self, validated_data):
        # 유저 생성
        validated_data.pop('password_confirm')
        password = validated_data.pop('user_password')
        user_type = validated_data.pop('user_type')

        user = User.objects.create_user(
            user_email=validated_data['user_email'],
            password=password,
            user_name=validated_data['user_name'],
            user_phone=validated_data['user_phone'],
            user_type=user_type,  # 계정 생성 시 사용자로 고정
            profile_img_id=None
        )
        return user

class PasswordResetRequestSerializer(serializers.Serializer):
    # 비밀번호 재설정 링크 요청
    user_email = serializers.EmailField()

    def validate_user_email(self, value):
        # 재설정 계속하는 것으로 이메일 계정이 존재하는 지 안 하는지 확인 하는 것 막기 위해 미존재 시에도 성공 응답 반환
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    # 새 비밀번호 저장
    token = serializers.UUIDField()
    user_password = serializers.CharField(write_only=True, min_length=8, max_length=20)
    password_confirm = serializers.CharField(write_only=True)

    def validate_user_password(self, value):
        import re
        regex = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$'
        if not re.match(regex, value):
            raise serializers.ValidationError(
                "비밀번호는 8~20자이며, 영문, 숫자, 특수문자를 모두 포함해야 합니다."
            )
        return value

    def validate(self, data):
        if data.get('user_password') != data.get('password_confirm'):
            raise serializers.ValidationError({"password_confirm": "비밀번호가 일치하지 않습니다."})
        return data


# -------- 마이페이지

class ProfileImageSerializer(serializers.Serializer):
    img_id   = serializers.IntegerField()
    img_name = serializers.CharField()
    img_url  = serializers.CharField()
    img_path = serializers.CharField()


class UserProfileSerializer(serializers.ModelSerializer):
    # GET /users/me -> 내 프로필 조회
    profile_img = serializers.SerializerMethodField()
    reg_dt      = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")

    class Meta:
        model  = User
        fields = [
            'user_id', 'user_name', 'user_email',
            'user_phone', 'user_type', 'profile_img', 'reg_dt',
        ]

    def get_profile_img(self, obj):
        if not obj.profile_img_id:
            return None
        try:
            from image.models.image import Image
            img = Image.objects.get(img_id=obj.profile_img_id)
            return ProfileImageSerializer(img).data
        except Image.DoesNotExist:
            return None


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    # PUT /users/me -> 프로필 수정 (모든 필드 optional임)
    user_name  = serializers.CharField(min_length=2, max_length=20, required=False)
    user_email = serializers.EmailField(max_length=50, required=False)
    user_phone = serializers.CharField(max_length=30, required=False)

    class Meta:
        model  = User
        fields = ['user_name', 'user_email', 'user_phone']

    def validate_user_phone(self, value):
        if not re.match(r'^010-\d{4}-\d{4}$', value):
            raise serializers.ValidationError(
                "전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678)"
            )
        return value

    def validate_user_email(self, value):
        # 자기 자신 이외 중복 체크
        user = self.context['request'].user
        if User.objects.exclude(pk=user.pk).filter(user_email=value).exists():
            raise serializers.ValidationError("이미 사용 중인 이메일입니다.")
        return value

    def update(self, instance, validated_data):
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save(update_fields=list(validated_data.keys()))
        return instance


class PasswordChangeSerializer(serializers.Serializer):
    # PATCH /users/me/password — 로그인 상태에서 비밀번호 변경
    current_password     = serializers.CharField(write_only=True)
    new_password         = serializers.CharField(write_only=True, min_length=8, max_length=20)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_new_password(self, value):
        regex = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$'
        if not re.match(regex, value):
            raise serializers.ValidationError(
                "비밀번호는 8~20자이며, 영문, 숫자, 특수문자를 모두 포함해야 합니다."
            )
        return value

    def validate(self, data):
        if data['new_password'] != data['new_password_confirm']:
            raise serializers.ValidationError(
                {"new_password_confirm": "새 비밀번호가 일치하지 않습니다."}
            )
        if data['current_password'] == data['new_password']:
            raise serializers.ValidationError(
                {"new_password": "VAL_001"}
            )
        return data


# --------- 위치 로그

class LocationLogCreateSerializer(serializers.Serializer):
    """POST /users/me/locations 요청 검증"""
    lat = serializers.FloatField()
    lon = serializers.FloatField()

    def validate_lat(self, value):
        if not (-90.0 <= value <= 90.0):
            raise serializers.ValidationError("위도는 -90 ~ 90 사이여야 합니다.")
        return value

    def validate_lon(self, value):
        if not (-180.0 <= value <= 180.0):
            raise serializers.ValidationError("경도는 -180 ~ 180 사이여야 합니다.")
        return value


class LocationLogResponseSerializer(serializers.ModelSerializer):
    """위치 로그 응답 직렬화"""
    reg_dt = serializers.DateTimeField(format="%Y-%m-%dT%H:%M:%SZ")

    class Meta:
        from user.models.location_log import LocationLog
        model  = LocationLog
        fields = ['log_id', 'lat', 'lon', 'reg_dt']