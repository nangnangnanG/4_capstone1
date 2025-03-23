from rest_framework import serializers
from .models import User
from django.contrib.auth.hashers import make_password

class UserSerializer(serializers.ModelSerializer):
    # 비밀번호 필드를 write_only=True로 설정하여 응답에서 제외
    password = serializers.CharField(write_only=True, allow_null=True, required=False)

    class Meta:
        model = User
        fields = '__all__'  # 모든 필드를 포함


    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)  # create_user() 사용
        return user