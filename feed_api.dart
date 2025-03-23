import 'dart:io';
import 'dart:async';
import 'api_service.dart';

class FeedApi {
  // ✅ 피드 목록 가져오기
  static Future<dynamic> fetchFeeds() async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/feeds/",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ✅ 내 피드 목록 가져오기
  static Future<dynamic> fetchMyFeeds() async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/feeds/my-feeds/",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ✅ 피드 상세 정보 가져오기
  static Future<dynamic> fetchFeedDetail(String feedId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/feeds/$feedId/",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ✅ 피드 생성하기 (개선된 버전)
  static Future<dynamic> createFeed({
    required String title,
    required String content,
    required String artifactName,
    required List<File> images,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 진행 상황 보고를 위한 변수
      double totalProgress = 0.0;
      final double createFeedWeight = 0.2; // 피드 생성은 전체 프로세스의 20%
      final double uploadImagesWeight = 0.8; // 이미지 업로드는 전체 프로세스의 80%

      // 먼저 피드 정보만 생성
      var feedResult = await ApiService.sendRequest(
        endpoint: "/api/feeds/",
        method: "POST",
        body: {
          "title": title,
          "content": content,
          "artifact_name": artifactName,
          "status": "published",
        },
      );

      // 진행 상황 업데이트
      totalProgress += createFeedWeight;
      onProgress?.call(totalProgress);

      // 피드 생성 실패 시 에러 반환
      if (feedResult is Map && feedResult.containsKey("error")) {
        return feedResult;
      }

      // feedResult가 Map이 아니거나 id가 없는 경우
      String? feedId;
      if (feedResult is Map && feedResult.containsKey("id")) {
        feedId = feedResult["id"].toString();
      } else {
        return {"error": "피드 생성 응답에서 ID를 찾을 수 없습니다"};
      }

      // 이미지가 있을 경우 배치 방식으로 업로드
      if (images.isNotEmpty) {
        final int batchSize = 2; // 한 번에 처리할 이미지 수
        final double progressPerBatch = uploadImagesWeight /
            ((images.length / batchSize).ceil());

        for (int i = 0; i < images.length; i += batchSize) {
          final int end = (i + batchSize < images.length) ? i + batchSize : images.length;
          final List<File> batch = images.sublist(i, end);

          try {
            // 각 배치 업로드 전 잠시 지연
            await Future.delayed(Duration(milliseconds: 100));

            await uploadFeedImages(feedId, batch);

            // 이번 배치 완료 후 진행 상황 업데이트
            totalProgress += progressPerBatch;
            onProgress?.call(totalProgress > 1.0 ? 1.0 : totalProgress);

            // 서버가 응답할 시간을 주기 위한 짧은 지연
            await Future.delayed(Duration(milliseconds: 200));
          } catch (e) {
            return {"error": "이미지 업로드 중 오류 발생: ${e.toString()}"};
          }
        }
      }

      // 서버 처리 시간을 위한 지연
      await Future.delayed(Duration(milliseconds: 300));

      // 최종 피드 정보 반환
      return await fetchFeedDetail(feedId);
    } catch (e) {
      return {"error": "피드 생성 중 오류 발생: ${e.toString()}"};
    }
  }

  // ✅ 피드 이미지 업로드 (개선된 버전)
  static Future<dynamic> uploadFeedImages(String feedId, List<File> images) async {
    try {
      // 이미지가 없으면 바로 성공 반환
      if (images.isEmpty) {
        return {"message": "No images to upload"};
      }

      // 이미지 업로드를 위한 MultipartRequest 사용
      return await ApiService.sendMultipartRequest(
        endpoint: "/api/feeds/$feedId/upload-images/",
        method: "POST",
        files: images.map((file) => {"name": "images", "file": file}).toList(),
      );
    } catch (e) {
      return {"error": "이미지 업로드 중 오류 발생: ${e.toString()}"};
    }
  }

  // ✅ 피드 업데이트
  static Future<dynamic> updateFeed({
    required String feedId,
    String? title,
    String? content,
    String? artifactName,
    String? status,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (title != null) body["title"] = title;
      if (content != null) body["content"] = content;
      if (artifactName != null) body["artifact_name"] = artifactName;
      if (status != null) body["status"] = status;

      return await ApiService.sendRequest(
        endpoint: "/api/feeds/$feedId/update/",
        method: "PATCH",
        body: body,
      );
    } catch (e) {
      return {"error": "피드 업데이트 중 오류 발생: ${e.toString()}"};
    }
  }

  // ✅ 피드 삭제
  static Future<dynamic> deleteFeed(String feedId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/feeds/$feedId/delete/",
        method: "DELETE",
      );
    } catch (e) {
      return {"error": "피드 삭제 중 오류 발생: ${e.toString()}"};
    }
  }
}