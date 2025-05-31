from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import Artifact, ArtifactFeed
from feeds.models import Feed, FeedImage


class RelatedImagesInline(admin.StackedInline):
    model = FeedImage
    extra = 0
    max_num = 0
    can_delete = False
    readonly_fields = ['image_preview']
    fields = ['image_preview']
    verbose_name = "관련 이미지"
    verbose_name_plural = "관련 이미지들"
    
    def get_queryset(self, request):
        # 현재 아티팩트 연결된 피드 이미지만 조회
        qs = super().get_queryset(request)
        artifact_id = request.resolver_match.kwargs.get('object_id')
        if artifact_id:
            feed_ids = ArtifactFeed.objects.filter(artifact_id=artifact_id).values_list('feed_id', flat=True)
            return qs.filter(feed_id__in=feed_ids)
        return qs.none()
    
    def image_preview(self, obj):
        if obj.image_url:
            return mark_safe(f'<img src="{obj.image_url}" style="max-width:400px; max-height:300px" />')
        return "이미지 없음"
    
    image_preview.short_description = "이미지 미리보기"
    
    def has_add_permission(self, request, obj=None):
        return False


class ArtifactFeedInline(admin.TabularInline):
    model = ArtifactFeed
    extra = 0
    can_delete = True
    fields = ['feed', 'feed_images']
    readonly_fields = ['feed_images']
    
    def feed_images(self, obj):
        images = FeedImage.objects.filter(feed=obj.feed)
        html = ""
        for image in images:
            html += f'<img src="{image.image_url}" style="max-width:200px; max-height:150px; margin:5px" />'
        return mark_safe(html) if html else "이미지 없음"
    
    feed_images.short_description = "피드 이미지"


@admin.register(Artifact)
class ArtifactAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'status', 'image_count', 'time_period', 'origin_location', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('name', 'description')
    readonly_fields = ['all_images']
    inlines = [ArtifactFeedInline]
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('name', 'description', 'status', 'image_count')
        }),
        ('출처 정보', {
            'fields': ('time_period', 'estimated_year', 'origin_location')
        }),
        ('모든 이미지', {
            'fields': ('all_images',),
        }),
    )
    
    def all_images(self, obj):
        artifact_feeds = ArtifactFeed.objects.filter(artifact=obj)
        feed_ids = artifact_feeds.values_list('feed_id', flat=True)
        images = FeedImage.objects.filter(feed_id__in=feed_ids)
        
        html = "<div style='display:flex; flex-wrap:wrap;'>"
        for image in images:
            html += f"""
            <div style='margin:10px; text-align:center;'>
                <img src="{image.image_url}" style="max-width:300px; max-height:300px; object-fit:contain;" />
                <p>Feed ID: {image.feed.id}</p>
            </div>
            """
        html += "</div>"
        
        return mark_safe(html) if images.exists() else "이미지 없음"
    
    all_images.short_description = "모든 관련 이미지"


@admin.register(ArtifactFeed)
class ArtifactFeedAdmin(admin.ModelAdmin):
    list_display = ('id', 'artifact_display', 'feed_display', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('artifact__name',)
    readonly_fields = ['feed_images']
    
    def artifact_display(self, obj):
        return obj.artifact.name if obj.artifact else "N/A"
    
    artifact_display.short_description = "Artifact"
    
    def feed_display(self, obj):
        return f"Feed #{obj.feed.id} - {obj.feed.artifact_name}" if obj.feed else "N/A"
    
    feed_display.short_description = "Feed"
    
    def feed_images(self, obj):
        images = FeedImage.objects.filter(feed=obj.feed)
        html = "<div style='display:flex; flex-wrap:wrap;'>"
        for image in images:
            html += f"""
            <div style='margin:10px; text-align:center;'>
                <img src="{image.image_url}" style="max-width:300px; max-height:300px; object-fit:contain;" />
            </div>
            """
        html += "</div>"
        
        return mark_safe(html) if images.exists() else "이미지 없음"
    
    feed_images.short_description = "피드 이미지"
    
    fieldsets = (
        (None, {
            'fields': ('artifact', 'feed')
        }),
        ('피드 이미지', {
            'fields': ('feed_images',),
        }),
    )