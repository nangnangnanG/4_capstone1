import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ongi_flutter/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/api_service.dart';

class UserProvider extends ChangeNotifier {
  String _username = "Loading...";
  String _email = "";
  String _gender = "";
  String _phoneNumber = "";
  String _profileImage = "";
  String _userId = "";
  String _rank = "입문자";
  int _rankNumber = 1; // rank 숫자 추가
  bool _isLoaded = false;
  String _error = ""; // 오류 메시지 저장

  // Getters
  String get username => _username;
  String get email => _email;
  String get gender => _gender;
  String get phoneNumber => _phoneNumber;
  String get profileImage => _profileImage;
  String get userId => _userId;
  String get rank => _rank;
  int get rankNumber => _rankNumber; // rank 숫자 getter 추가
  bool get isLoaded => _isLoaded;
  String get error => _error;

  // rank 숫자를 텍스트로 변환하는 메서드
  String _getRankText(int rank) {
    switch (rank) {
      case 1: return '입문자';
      case 2: return '관찰자';
      case 3: return '탐험가';
      case 4: return '지킴이';
      case 5: return '고고학자';
      case 6: return '도굴꾼';
      default: return '입문자';
    }
  }

  // 이미지 URL을 올바르게 변환하는 메서드
  String _formatImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return "";

    // 이미 완전한 URL(http 또는 https로 시작하는)인 경우 그대로 반환
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // 파일 URI인 경우 변환 (file:///으로 시작하는 경우)
    if (imageUrl.startsWith('file:///')) {
      return imageUrl;
    }

    // 상대 경로인 경우 baseUrl 추가
    // 슬래시로 시작하지 않는 경우 슬래시 추가
    String formattedUrl = imageUrl;
    if (!formattedUrl.startsWith('/')) {
      formattedUrl = '/$formattedUrl';
    }

    // 최종 URL 생성
    String fullUrl = "${ApiService.baseUrl}$formattedUrl";
    print("📢 최종 형식화된 이미지 URL: $fullUrl");

    return fullUrl;
  }

  // 인증 상태 확인 및 리셋 (필요 시)
  Future<bool> checkAndResetAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString("auth_token");
    String? userId = prefs.getString("user_id");

    print("🔐 저장된 auth_token: $authToken");
    print("🔐 저장된 user_id: $userId");

    // 샘플 토큰이나 불완전한 인증 정보 감지
    if (authToken == "sample_token_12345" || (authToken != null && authToken.isEmpty) || (userId == null || userId.isEmpty)) {
      print("⚠️ 유효하지 않은 인증 정보가 감지되었습니다. 로그아웃 처리합니다.");
      await prefs.remove("auth_token");
      await prefs.remove("user_id");
      await prefs.setBool("is_logged_in", false);
      await reset();
      return false;
    }
    return true;
  }

  // 사용자 정보 로드
  Future<void> loadUserInfo({bool forceRefresh = false}) async {
    print("✅ loadUserInfo() 실행됨, forceRefresh: $forceRefresh");

    // forceRefresh가 true면 기존 상태 초기화
    if (forceRefresh) {
      _isLoaded = false;
      _username = "Loading...";
      _email = "";
      _gender = "";
      _phoneNumber = "";
      _profileImage = "";
      // userId는 아직 초기화하지 않음
      _rankNumber = 1;
      _rank = "입문자";
    }

    if (!forceRefresh && _isLoaded) {
      print("⚠️ 이미 사용자 정보가 로드되어 있어 로드를 건너뜁니다.");
      return;
    }

    _error = ""; // 오류 초기화

    try {
      // 인증 토큰 가져오기
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString("auth_token");
      _userId = prefs.getString("user_id") ?? "";

      print("🔐 저장된 auth_token: $authToken");
      print("🔐 저장된 user_id: $_userId");

      // 인증 토큰이 없거나 user_id가 없으면 게스트 모드로 설정
      if (authToken == null || authToken.isEmpty || _userId.isEmpty) {
        print("⚠️ 인증 정보가 유효하지 않습니다.");
        _error = "인증 정보가 유효하지 않습니다. 다시 로그인해 주세요.";
        _username = "Guest";
        _isLoaded = true;
        notifyListeners();
        return;
      }

      // 항상 서버에서 최신 사용자 정보 가져오기
      Map<String, dynamic> userInfo = await UserApi.fetchUserInfo();
      print("📊 서버 응답 전체: $userInfo");
      print("📊 랭크 정보: ${userInfo['rank']}");
      print("📊 피드 카운트: ${userInfo['feed_count']}");

      if (userInfo.containsKey("error")) {
        _error = userInfo["error"].toString();
        _username = "Guest";
        print("❌ 사용자 정보 가져오기 실패: $_error");

        // 인증 관련 오류인 경우
        if (_error.contains("403") || _error.contains("401") ||
            _error.contains("authentication") || _error.contains("token")) {
          _error = "인증이 만료되었습니다. 다시 로그인해 주세요.";
          // 인증 정보 리셋
          await prefs.remove("auth_token");
          await prefs.remove("user_id");
          await prefs.setBool("is_logged_in", false);
        }
      } else {
        // 서버에서 가져온 정보가 있으면 업데이트
        if (userInfo.containsKey("id")) {
          _userId = userInfo["id"]?.toString() ?? "";

          // 서버에서 가져온 userId와 로컬 저장된 userId가 다른 경우 업데이트
          if (_userId != prefs.getString("user_id")) {
            await prefs.setString("user_id", _userId);
            print("✅ user_id 업데이트: $_userId");
          }
        }

        _username = userInfo["username"] ?? "Guest";
        _email = userInfo["email"] ?? "";
        _gender = userInfo["gender"] ?? "";
        _phoneNumber = userInfo["phone_number"] ?? "";

        _rankNumber = userInfo["rank"] ?? 1;
        _rank = _getRankText(_rankNumber);

        // 프로필 이미지 URL 처리
        String originalImageUrl = userInfo["profile_image"] ?? "";
        print("📢 서버에서 받은 원본 프로필 이미지 URL: $originalImageUrl");

        _profileImage = _formatImageUrl(originalImageUrl);

        // 캐시 방지를 위한 타임스탬프 추가
        if (_profileImage.isNotEmpty) {
          _profileImage = "$_profileImage?t=${DateTime.now().millisecondsSinceEpoch}";
        }

        print("📢 변환된 프로필 이미지 URL: $_profileImage");
        print("✅ 사용자 정보 로드 완료: 사용자명=$_username, 이메일=$_email");
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("❌ 사용자 정보 로드 실패: $e");
      _error = "사용자 정보를 불러오는 중 오류가 발생했습니다: $e";
      _username = "Guest";
      _isLoaded = true;
      notifyListeners();
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserInfo({
    String? username,
    String? email,
    String? gender,
    String? phoneNumber,
  }) async {
    if (_userId.isEmpty) {
      print("❌ 사용자 ID가 없어 업데이트할 수 없습니다");
      _error = "사용자 ID가 없어 업데이트할 수 없습니다";
      notifyListeners();
      return;
    }

    try {
      Map<String, dynamic> result = await UserApi.updateUserInfo(
        userId: _userId,
        username: username,
        email: email,
        gender: gender,
        phoneNumber: phoneNumber,
      );

      if (result.containsKey("error")) {
        _error = result["error"].toString();
        print("❌ 사용자 정보 업데이트 실패: $_error");

        // 인증 관련 오류인 경우
        if (_error.contains("403") || _error.contains("401") ||
            _error.contains("authentication") || _error.contains("token")) {
          _error = "인증이 만료되었습니다. 다시 로그인해 주세요.";
          // 인증 정보 리셋
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove("auth_token");
          await prefs.remove("user_id");
          await prefs.setBool("is_logged_in", false);
        }

        notifyListeners();
        return;
      }

      // 로컬 상태 업데이트
      _username = username ?? _username;
      _email = email ?? _email;
      _gender = gender ?? _gender;
      _phoneNumber = phoneNumber ?? _phoneNumber;

      _error = ""; // 성공 시 오류 메시지 초기화
      notifyListeners();
      print("✅ 사용자 정보 업데이트 완료");
    } catch (e) {
      print("❌ 사용자 정보 업데이트 실패: $e");
      _error = "사용자 정보 업데이트 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    print("✅ updateProfileImage() 실행됨");

    // ✅ SharedPreferences에서 user_id 가져오기
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id") ?? "";
    String? authToken = prefs.getString("auth_token");

    print("✅ SharedPreferences에서 가져온 user_id: $_userId");
    print("✅ SharedPreferences에서 가져온 auth_token: $authToken");

    if (_userId.isEmpty) {
      print("❌ 사용자 ID가 없어 프로필 이미지를 변경할 수 없습니다.");
      _error = "사용자 ID가 없어 프로필 이미지를 변경할 수 없습니다.";
      notifyListeners();
      return;
    }

    try {
      Map<String, dynamic> result = await UserApi.updateProfileImage(
        userId: _userId,
        profileImage: imageFile,
      );

      if (result.containsKey("error")) {
        _error = result["error"].toString();
        print("❌ 프로필 이미지 업데이트 실패: $_error");

        // 인증 관련 오류인 경우
        if (_error.contains("403") || _error.contains("401") ||
            _error.contains("authentication") || _error.contains("token")) {
          _error = "인증이 만료되었습니다. 다시 로그인해 주세요.";
          // 인증 정보 리셋
          await prefs.remove("auth_token");
          await prefs.remove("user_id");
          await prefs.setBool("is_logged_in", false);
        }

        notifyListeners();
        return;
      }

      String originalImageUrl = result["profile_image"] ?? "";
      print("📢 서버에서 받은 원본 프로필 이미지 URL: $originalImageUrl");

      _profileImage = _formatImageUrl(originalImageUrl);

      // 캐시 방지를 위한 타임스탬프 추가
      if (_profileImage.isNotEmpty) {
        _profileImage = "$_profileImage?t=${DateTime.now().millisecondsSinceEpoch}";
      }

      print("📢 변환된 프로필 이미지 URL: $_profileImage");

      _error = ""; // 성공 시 오류 메시지 초기화
      notifyListeners();
      print("✅ 프로필 이미지 업데이트 완료");
    } catch (e) {
      print("❌ 프로필 이미지 업데이트 실패: $e");
      _error = "프로필 이미지 업데이트 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  // 로그아웃 시 상태 초기화
  Future<void> reset() async {
    print("✅ UserProvider.reset() 실행됨");
    _username = "Loading...";
    _email = "";
    _gender = "";
    _phoneNumber = "";
    _profileImage = "";
    _userId = "";
    _rankNumber = 1;
    _rank = "입문자";
    _isLoaded = false;
    _error = "";

    // SharedPreferences에서도 사용자 정보 삭제
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_id");
    await prefs.setBool("is_logged_in", false);

    print("✅ 모든 사용자 정보 초기화 완료");
    notifyListeners();
  }

  // 오류 메시지 초기화
  void clearError() {
    _error = "";
    notifyListeners();
  }
}