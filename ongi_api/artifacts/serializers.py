from rest_framework import serializers
from .models import Artifact, ArtifactFeed
from feeds.models import Feed
from feeds.serializers import FeedSerializer, UserMinimalSerializer

class ArtifactSerializer(serializers.ModelSerializer):
    """유물 정보 시리얼라이저"""
    feed_count = serializers.SerializerMethodField()
    has_3d_model = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()  # 추가
    
    class Meta:
        model = Artifact
        fields = [
            'id', 'name', 'description', 'time_period', 'estimated_year',
            'origin_location', 'status', 'image_count', 'feed_count',
            'has_3d_model', 'thumbnail_url', 'created_at', 'updated_at'  # thumbnail_url 추가
        ]
        read_only_fields = ['id', 'image_count', 'created_at', 'updated_at']
    
    def get_feed_count(self, obj):
        """연관된 피드 수를 반환"""
        return obj.artifact_feeds.count()
    
    def get_has_3d_model(self, obj):
        """3D 모델 존재 여부를 반환"""
        return obj.models.filter(status='completed').exists()
        
    def get_thumbnail_url(self, obj):
        """썸네일 URL 반환"""
        # 연결된 3D 모델이 있으면 그 썸네일 사용
        model = obj.models.filter(status='completed').first()
        if model and model.thumbnail_url:
            return model.thumbnail_url.url
            
        # 아니면 연결된 피드의 첫 번째 이미지 사용
        artifact_feed = obj.artifact_feeds.first()
        if artifact_feed:
            feed = artifact_feed.feed
            feed_image = feed.images.first()
            if feed_image:
                return feed_image.image_url
                
        # 기본 이미지 없음
        return None

class ArtifactDetailSerializer(ArtifactSerializer):
    """유물 상세 정보 시리얼라이저"""
    feeds = serializers.SerializerMethodField()
    
    class Meta(ArtifactSerializer.Meta):
        fields = ArtifactSerializer.Meta.fields + ['feeds']
    
    def get_feeds(self, obj):
        """연관된 피드 목록을 반환 (최대 5개)"""
        artifact_feeds = ArtifactFeed.objects.filter(artifact=obj).select_related('feed')[:5]
        feeds = [item.feed for item in artifact_feeds]
        return FeedSerializer(feeds, many=True).data