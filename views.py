import logging
import os
import posixpath
from .models import User, CustomToken
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db import connection
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.conf import settings
from .models import User
from feeds.models import Feed


User = get_user_model()

logger = logging.getLogger(__name__)

@api_view(['POST'])
def user_create_view(request):
    logger.info(f"🔵 요청 데이터: {request.data}")  
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        logger.info(f"저장 성공! ID: {user.id}")  
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    logger.error(f"저장 실패! 오류: {serializer.errors}")  
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def user_login_view(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response({"error": "이메일과 비밀번호를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

    if user.check_password(password):
        # CustomToken 모델을 사용하여 실제 토큰 생성
        token, created = CustomToken.objects.get_or_create(user=user)
        return Response({
            "auth_token": token.key,  # 실제 토큰 키 반환
            "user_id": str(user.id)
        }, status=status.HTTP_200_OK)
    else:
        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=status.HTTP_401_UNAUTHORIZED)



@api_view(['GET'])
def get_user_info(request, user_id):
    try:
        user = User.objects.get(id=user_id)
        
        # 사용자의 피드 수를 실시간으로 계산
        from feeds.models import Feed
        feed_count = Feed.objects.filter(user=user, status='published').count()
        
        # 계산된 피드 수로 사용자 정보 업데이트
        user.feed_count = feed_count
        user.update_rank()  # 랭크 업데이트 메서드 호출
        user.save()  # 변경된 정보 저장
        
        # 안전하게 값 가져오기
        response_data = {
            'username': str(user.username) if hasattr(user, 'username') else '',
            'email': str(user.email) if hasattr(user, 'email') else '',
            'gender': str(user.gender) if hasattr(user, 'gender') else '',
            'phone_number': str(user.phone_number) if hasattr(user, 'phone_number') else '',
            'id': str(user.id)
        }
        
        # 추가 필드들 안전하게 추가
        if hasattr(user, 'profile_image'):
            response_data['profile_image'] = str(user.profile_image)
        
        if hasattr(user, 'created_at'):
            try:
                response_data['created_at'] = user.created_at.isoformat() if user.created_at else None
            except:
                response_data['created_at'] = None
        
        if hasattr(user, 'rank'):
            try:
                response_data['rank'] = int(user.rank) if user.rank is not None else 1
            except:
                response_data['rank'] = 1
        
        # 실시간으로 계산된 피드 수 사용
        response_data['feed_count'] = feed_count
        
        return Response(response_data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()  # 더 자세한 오류 정보 출력
        return Response({'error': f'Server Error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@parser_classes([MultiPartParser])
def update_user_info(request, user_id):
    try:
        user = User.objects.get(id=user_id)

        # ✅ request.data에서 None이 아닌 값만 업데이트
        update_fields = ['username', 'email', 'gender', 'phone_number', 'rank', 'feed_count']
        for field in update_fields:
            value = request.data.get(field)
            if value is not None:  # None이 아닐 때만 업데이트
                setattr(user, field, value)

        # ✅ 프로필 사진 처리
        if "file" in request.FILES:
            image_file = request.FILES["file"]
            user_folder = os.path.join(settings.MEDIA_ROOT, str(user.id), "profile")
            file_path = os.path.join(user_folder, "profile.jpg")

            # 기존 프로필 사진 삭제
            if os.path.exists(user_folder):
                for file_name in os.listdir(user_folder):
                    file_path_to_delete = os.path.join(user_folder, file_name)
                    os.remove(file_path_to_delete)

            os.makedirs(user_folder, exist_ok=True)
            default_storage.save(file_path, ContentFile(image_file.read()))

            image_url = posixpath.join(settings.MEDIA_URL, str(user.id), "profile", "profile.jpg").replace("\\", "/")
            user.profile_image = image_url

        user.save()

        return Response({
            "message": "User info updated successfully",
            "user_id": str(user.id),
            "username": user.username,
            "profile_image": user.profile_image,
            "email": user.email,
            "gender": user.gender,
            "phone_number": user.phone_number,
            "rank": user.rank,
            "feed_count": user.feed_count,
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({"error": "Server Error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@parser_classes([MultiPartParser])
def update_profile_image(request, user_id):
    try:
        user = User.objects.get(id=user_id)
        
        if "file" in request.FILES:
            image_file = request.FILES["file"]
            user_folder = os.path.join(settings.MEDIA_ROOT, str(user.id), "profile")
            file_path = os.path.join(user_folder, "profile.jpg")
            
            # 기존 프로필 사진 삭제
            if os.path.exists(user_folder):
                for file_name in os.listdir(user_folder):
                    file_path_to_delete = os.path.join(user_folder, file_name)
                    os.remove(file_path_to_delete)
            
            os.makedirs(user_folder, exist_ok=True)
            default_storage.save(file_path, ContentFile(image_file.read()))
            
            image_url = posixpath.join(settings.MEDIA_URL, str(user.id), "profile", "profile.jpg").replace("\\", "/")
            user.profile_image = image_url
            user.save(update_fields=['profile_image'])  # 프로필 이미지 필드만 업데이트
            
            return Response({
                "message": "Profile image updated successfully",
                "user_id": str(user.id),
                "profile_image": user.profile_image
            }, status=status.HTTP_200_OK)
        else:
            return Response({"error": "No image file provided"}, status=status.HTTP_400_BAD_REQUEST)
        
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({"error": "Server Error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)