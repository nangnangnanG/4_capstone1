import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpProvider extends ChangeNotifier {
  String _email = '';
  String? _password = '';
  String _birthDate = '';
  String _gender = '';
  String _username = '';
  String _phoneNumber = '';
  String _provider = '';
  String _authToken = "";
  bool _isLoggedIn = false;

  String get email => _email;
  String? get password => _password;
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get username => _username;
  String get phoneNumber => _phoneNumber;
  String get provider => _provider;
  String get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;

  void setEmail(String email) {
    _email = email;
    notifyListeners(); // 데이터가 변경되었음을 알림 (UI 업데이트)
  }

  void setPassword(String? password) {
    _password = password;
    notifyListeners();
  }

  void setBirthDate(String birthDate) {
    _birthDate = birthDate;
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  void setProvider(String provider) {
    _provider = provider;
    notifyListeners();
  }


  Future<void> setAuthToken(String? token) async { // String?로 변경
    _authToken = token ?? ""; // null이면 빈 문자열 사용
    _isLoggedIn = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token ?? ""); // null 체크 추가
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> loadAuthToken() async { // ✅ 앱 실행 시 로그인 상태 불러오기
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token') ?? "";
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners();
  }

  Future<void> setLoggedIn(bool status) async { // ✅ 로그인 상태 저장
    _isLoggedIn = status;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', status);
  }

  Future<void> logout() async { // ✅ 로그아웃 기능 추가
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_logged_in');
    _authToken = "";
    _isLoggedIn = false;
    notifyListeners();
  }

}