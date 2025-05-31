from django.urls import path
from .views import (
    artifact_list_view,
    artifact_detail_view,
    artifact_update_view,
    artifact_feeds_view,
)

urlpatterns = [
    path('', artifact_list_view, name='artifact-list'),  # 유물 목록 조회
    path('<uuid:artifact_id>/', artifact_detail_view, name='artifact-detail'),  # 유물 상세 조회
    path('<uuid:artifact_id>/update/', artifact_update_view, name='artifact-update'),  # 유물 정보 수정
    path('<uuid:artifact_id>/feeds/', artifact_feeds_view, name='artifact-feeds'),  # 유물 관련 피드 조회
]