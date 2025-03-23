import 'api_service.dart';

class ArtifactApi {
  // 유물 목록 가져오기
  static Future<dynamic> fetchArtifacts({String status = 'verified'}) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/artifacts/?status=$status",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // 유물 상세 정보 가져오기
  static Future<dynamic> fetchArtifactDetail(String artifactId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/artifacts/$artifactId/",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // 유물 관련 피드 가져오기
  static Future<dynamic> fetchArtifactFeeds(String artifactId) async {
    try {
      return await ApiService.sendRequest(
        endpoint: "/api/artifacts/$artifactId/feeds/",
        method: "GET",
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // 유물 상태 업데이트 (관리자만 가능)
  static Future<dynamic> updateArtifact({
    required String artifactId,
    String? name,
    String? description,
    String? timePeriod,
    String? estimatedYear,
    String? originLocation,
    String? status,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (name != null) body["name"] = name;
      if (description != null) body["description"] = description;
      if (timePeriod != null) body["time_period"] = timePeriod;
      if (estimatedYear != null) body["estimated_year"] = estimatedYear;
      if (originLocation != null) body["origin_location"] = originLocation;
      if (status != null) body["status"] = status;

      return await ApiService.sendRequest(
        endpoint: "/api/artifacts/$artifactId/update/",
        method: "PATCH",
        body: body,
      );
    } catch (e) {
      return {"error": e.toString()};
    }
  }
}