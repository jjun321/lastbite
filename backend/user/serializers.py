import re
from rest_framework import serializers
from user.models.user import User
# 회원가입 유효성 검사하고 유효할 시 유저 생성하는데 사용
class RegisterSerializer(serializers.ModelSerializer):
    password_confirm = serializers.CharField(write_only=True, required=True)
    user_password = serializers.CharField(write_only=True, required=True, min_length=8, max_length=20)
    user_phone = serializers.CharField(required=True, max_length=30)

    class Meta:
        model = User
        fields = ['user_name', 'user_email', 'user_phone', 'user_password', 'password_confirm']

    def validate_user_phone(self, value):
        # 전화번호 형식 검사
        if not re.match(r'^010-\d{4}-\d{4}$', value):
            raise serializers.ValidationError("전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678)")
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
        
        user = User.objects.create_user(
            user_email=validated_data['user_email'],
            password=password,
            user_name=validated_data['user_name'],
            user_phone=validated_data['user_phone'],
            user_type='U01',  # 계정 생성 시 사용자로 고정
            profile_img_id=None
        )
        return user