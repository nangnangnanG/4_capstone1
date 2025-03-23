import 'dart:io';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserApi {
  // ✅ 회원가입
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String? password,
    required String gender,
    required String username,
    required String phoneNumber,
    required String provider,
    String? profileImage,
  }) async {
    try {
      print("🚀 회원가입 API 요청 시작");
      Map<String, dynamic> response = await ApiService.sendRequest(
        endpoint: "/api/users/create/",
        method: "POST",
        body: {
          "email": email,
          "password": password,
          "gender": gender.toLowerCase(),
          "username": username,
          "phone_number": phoneNumber,
          "provider": provider,
          "profile_image": profileImage,
        },
      );
      print("✅ 회원가입 API 응답 받음: ${response.keys}");

      // 회원가입 후 auth_token이 응답에 포함되었다면, 저장
      if (response.containsKey("auth_token") && response["auth_token"] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", response["auth_token"]);
        print("✅ 회원가입 후 auth_token 저장: ${response["auth_token"]}");

        // 로그인된 상태로 설정
        await prefs.setBool("is_logged_in", true);
      } else {
        print("⚠️ 회원가입 응답에 auth_token이 없습니다");
      }

      // user_id 저장 (백엔드에서 id로 보낼 경우)
      if (response.containsKey("id") && response["id"] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", response["id"].toString());
        print("✅ 회원가입 후 user_id(id) 저장: ${response["id"]}");
      }
      // user_id 저장 (백엔드에서 user_id로 보낼 경우)
      else if (response.containsKey("user_id") && response["user_id"] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", response["user_id"].toString());
        print("✅ 회원가입 후 user_id 저장: ${response["user_id"]}");
      } else {
        print("⚠️ 회원가입 응답에 id 또는 user_id가 없습니다");
      }

      return response;
    } catch (e) {
      print("❌ 회원가입 요청 중 예외 발생: $e");
      return {"error": "회원가입 요청 중 오류가 발생했습니다: $e"};
    }
  }

  // ✅ 로그인
  static Future<Map<String, dynamic>> loginUser(String email, String? password) async {
    try {
      print("🚀 로그인 API 요청 시작");
      Map<String, dynamic> response = await ApiService.sendRequest(
        endpoint: "/api/users/login/",
        method: "POST",
        body: {"email": email, "password": password},
      );
      print("✅ 로그인 API 응답 받음: ${response.keys}");

      // 로그인 성공 후 auth_token이 응답에 포함되었다면, 저장
      if (response.containsKey("auth_token")) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", response["auth_token"]);
        print("✅ 로그인 후 auth_token 저장: ${response["auth_token"]}");

        // 로그인된 상태로 설정
        await prefs.setBool("is_logged_in", true);
      }

      return response;
    } catch (e) {
      print("❌ 로그인 요청 중 예외 발생: $e");
      return {"error": "로그인 요청 중 오류가 발생했습니다: $e"};
    }
  }

  // ✅ 유저 정보 가져오기 (GET)
  static Future<Map<String, dynamic>> fetchUserInfo() async {
    try {
      String? userId = await ApiService.getUserId();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString("auth_token");

      print("✅ 유저 정보 요청 준비: user_id=$userId, auth_token=${authToken != null ? '있음' : '없음'}");

      if (userId == null || userId.isEmpty) {
        print("❌ 사용자 ID가 없어 정보를 가져올 수 없습니다.");
        return {"error": "유효한 사용자 ID가 없습니다. 다시 로그인해 주세요."};
      }

      print("✅ 유저 정보 요청 시작 (ID: $userId)");
      Map<String, dynamic> response =
      await ApiService.sendRequest(endpoint: "/api/users/$userId/");

      // 응답에 오류가 있는지 확인
      if (response.containsKey("error")) {
        print("❌ 유저 정보 가져오기 실패: ${response["error"]}");

        // 인증 관련 오류면 로그아웃 처리
        if (response.containsKey("status") &&
            (response["status"] == 401 || response["status"] == 403)) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove("auth_token");
          await prefs.remove("user_id");
          await prefs.setBool("is_logged_in", false);
          print("⚠️ 인증 오류로 인한 로그아웃 처리");
        }

        return response;
      }

      print("✅ 유저 정보 가져오기 성공: ${response.toString().substring(0,
          response.toString().length > 100 ? 100 : response.toString().length)}...");

      // rank 필드가 있는지 확인하고 숫자로 변환
      if (response.containsKey("rank")) {
        try {
          response["rank"] = int.parse(response["rank"].toString());
        } catch (e) {
          print("⚠️ rank 필드 파싱 오류: $e, 원본 값: ${response["rank"]}");
          // 기본값으로 설정
          response["rank"] = 1;
        }
      }

      return response;
    } catch (e) {
      print("❌ 유저 정보 요청 중 예외 발생: $e");
      return {"error": "유저 정보 요청 중 오류가 발생했습니다: $e"};
    }
  }

  // ✅ 유저 정보 수정 (PATCH)
  static Future<Map<String, dynamic>> updateUserInfo({
    required String userId,
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
    File? profileImage,
  }) async {
    if (userId.isEmpty) {
      print("❌ 사용자 ID가 비어 있어 업데이트할 수 없습니다.");
      return {"error": "유효한 사용자 ID가 없습니다."};
    }

    return await ApiService.sendRequest(
      endpoint: "/api/users/$userId/update/",
      method: "PATCH",
      body: {
        "username": username,
        "email": email,
        "gender": gender,
        "phone_number": phoneNumber,
      },
      file: profileImage,
    );
  }

  // ✅ 프로필 이미지만 업데이트 (PATCH)
  static Future<Map<String, dynamic>> updateProfileImage({
    required String userId,
    required File profileImage,
  }) async {
    if (userId.isEmpty) {
      print("❌ 사용자 ID가 비어 있어 프로필 이미지를 업데이트할 수 없습니다.");
      return {"error": "유효한 사용자 ID가 없습니다."};
    }

    return await ApiService.sendRequest(
      endpoint: "/api/users/$userId/update-profile-image/",
      method: "PATCH",
      file: profileImage,
    );
  }
}