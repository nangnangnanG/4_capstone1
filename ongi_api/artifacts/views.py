from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from .models import Artifact, ArtifactFeed
from .serializers import ArtifactSerializer, ArtifactDetailSerializer
from feeds.serializers import FeedSerializer

@api_view(['GET'])
def artifact_list_view(request):
    """유물 목록 조회"""
    # 상태에 따른 필터링 (기본: 검증된 유물)
    status_filter = request.query_params.get('status', 'verified')
    
    if status_filter == 'all' and request.user.is_staff:
        # 관리자는 모든 상태의 유물 조회 가능
        artifacts = Artifact.objects.all().order_by('-created_at')
    elif status_filter == 'all':
        # 일반 사용자는 자동생성 + 검증됨 + 주목할만한 유물만 조회 가능
        artifacts = Artifact.objects.exclude(status='rejected').order_by('-created_at')
    else:
        # 특정 상태의 유물만 조회
        artifacts = Artifact.objects.filter(status=status_filter).order_by('-created_at')
    
    serializer = ArtifactSerializer(artifacts, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def artifact_detail_view(request, artifact_id):
    """유물 상세 정보 조회"""
    artifact = get_object_or_404(Artifact, id=artifact_id)
    
    # 거부된 유물은 관리자만 조회 가능
    if artifact.status == 'rejected' and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    serializer = ArtifactDetailSerializer(artifact)
    return Response(serializer.data)

@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated, IsAdminUser])
def artifact_update_view(request, artifact_id):
    """유물 정보 업데이트 (관리자 전용)"""
    artifact = get_object_or_404(Artifact, id=artifact_id)
    
    serializer = ArtifactSerializer(artifact, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def artifact_feeds_view(request, artifact_id):
    """특정 유물과 관련된 피드 목록 조회"""
    artifact = get_object_or_404(Artifact, id=artifact_id)
    
    # 거부된 유물은 관리자만 조회 가능
    if artifact.status == 'rejected' and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    # 페이지네이션 파라미터
    page_size = int(request.query_params.get('page_size', 10))
    page = int(request.query_params.get('page', 1))
    
    # 유물과 연결된 피드 찾기
    artifact_feeds = ArtifactFeed.objects.filter(artifact=artifact).select_related('feed')
    
    # 페이지네이션 적용
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    paginated_feeds = artifact_feeds[start_idx:end_idx]
    
    # 피드 목록 추출 및 직렬화
    feeds = [item.feed for item in paginated_feeds]
    serializer = FeedSerializer(feeds, many=True)
    
    response_data = {
        'results': serializer.data,
        'count': artifact_feeds.count(),
        'page': page,
        'page_size': page_size,
        'total_pages': (artifact_feeds.count() + page_size - 1) // page_size
    }
    
    return Response(response_data)