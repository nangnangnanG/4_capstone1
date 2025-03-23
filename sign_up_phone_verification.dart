import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/user_provider.dart';
import 'package:ongi_flutter/services/api/user_api.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

class SignUpPhoneVerificationPage extends StatefulWidget {
  const SignUpPhoneVerificationPage({Key? key}) : super(key: key);

  @override
  State<SignUpPhoneVerificationPage> createState() => _SignUpPhoneVerificationPageState();
}

class _SignUpPhoneVerificationPageState extends State<SignUpPhoneVerificationPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isPhoneValid = false;
  bool _isLoading = false; // ✅ API 요청 중 로딩 상태

  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneValid = value.isNotEmpty;
    });

    Provider.of<SignUpProvider>(context, listen: false).setPhoneNumber(value);
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isCodeSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("인증 코드가 전송되었습니다.")),
    );
  }

  void _onCodeChanged(String value) {
    if (value.length == 6) {
      _verifyCode(value);
    }
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("휴대폰 인증 완료!")),
    );
  }

  Future<void> _handleFinalSignUp() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("휴대폰 인증을 완료해야 합니다.")),
      );
      return;
    }

    final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    print("🚀 회원가입 요청 데이터:");
    print("📧 Email: ${signUpProvider.email}");
    print("🔑 Password: ${signUpProvider.password}");
    print("🧑‍🦰 Gender: ${signUpProvider.gender}");
    print("👤 Username: ${signUpProvider.username}");
    print("📱 Phone Number: ${signUpProvider.phoneNumber}");
    print("🌍 Provider: ${signUpProvider.provider}");

    // 기존 데이터 초기화
    await userProvider.reset();

    // ✅ API 요청 시작 (로딩 상태 적용)
    setState(() {
      _isLoading = true;
    });

    final response = await UserApi.createUser(
      email: signUpProvider.email,
      password: signUpProvider.password,
      gender: signUpProvider.gender,
      username: signUpProvider.username,
      phoneNumber: signUpProvider.phoneNumber,
      provider: signUpProvider.provider,
    );

    print("🟡 회원가입 API 응답: $response");
    print("🔍 회원가입 응답 키: ${response.keys.toList()}");
    print("🔍 회원가입 응답 값(일부): ${response.toString().substring(0, response.toString().length > 100 ? 100 : response.toString().length)}...");

    setState(() {
      _isLoading = false;
    });

    if (response.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 회원가입 실패: ${response["error"]}")),
      );
    } else {
      // 로그인 상태 설정
      signUpProvider.setLoggedIn(true);

      // 이 부분에서 auth_token 확인 및 저장
      String? authToken = response["auth_token"];
      if (authToken != null && authToken.isNotEmpty) {
        signUpProvider.setAuthToken(authToken);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", authToken);
        await prefs.setBool("is_logged_in", true);

        print("✅ 회원가입 후 auth_token 저장 완료: $authToken");
      } else {
        print("⚠️ 회원가입 응답에 auth_token이 없습니다. 로그인 시도...");

        // auth_token이 없으면 로그인 시도
        final loginResponse = await UserApi.loginUser(signUpProvider.email, signUpProvider.password);

        print("🔍 로그인 시도 응답: $loginResponse");
        print("🔍 로그인 시도 응답 키: ${loginResponse.keys.toList()}");

        if (loginResponse.containsKey("auth_token")) {
          authToken = loginResponse["auth_token"];
          signUpProvider.setAuthToken(authToken);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("auth_token", authToken ?? "");
          await prefs.setBool("is_logged_in", true);

          print("✅ 로그인 시도 후 auth_token 저장 완료: $authToken");
        } else {
          print("❌ 로그인 시도 실패: ${loginResponse["error"] ?? "알 수 없는 오류"}");
        }
      }

      // user_id 확인 및 저장
      String userId = "";
      if (response.containsKey("id")) {
        userId = response["id"].toString();
        print("✅ 회원가입 응답에서 id 필드 발견: $userId");
      } else if (response.containsKey("user_id")) {
        userId = response["user_id"].toString();
        print("✅ 회원가입 응답에서 user_id 필드 발견: $userId");
      }

      if (userId.isNotEmpty) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", userId);
        print("✅ 회원가입 후 user_id 저장 완료: $userId");
      } else {
        print("⚠️ 회원가입 응답에 user_id가 없습니다. 사용자 정보 로드 시도...");
      }

      // 사용자 정보 로드 요청 전에 상태 확인
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUserId = prefs.getString("user_id");
      String? savedAuthToken = prefs.getString("auth_token");
      print("✅ 사용자 정보 로드 요청 전 저장된 user_id: $savedUserId");
      print("✅ 사용자 정보 로드 요청 전 저장된 auth_token: $savedAuthToken");

      // 약간의 지연 후 사용자 정보 로드
      await Future.delayed(Duration(milliseconds: 500));
      print("✅ 사용자 정보 로드 요청");
      await userProvider.loadUserInfo(forceRefresh: true);

      // 사용자 정보 로드 후 상태 확인
      print("✅ 사용자 정보 로드 후 상태: username=${userProvider.username}, email=${userProvider.email}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 회원가입 성공!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabPage()),
      );
      print("✅ 회원가입 성공!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("회원가입", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("전화번호", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid && !_isCodeSent ? _sendVerificationCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoneValid && !_isCodeSent ? Colors.white : Colors.grey,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("다음", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 20),
                const Text("인증번호", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                  controller: _verificationCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  onChanged: _onCodeChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    counterText: "",
                  ),
                ),
              ],
              if (_isVerified) ...[
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleFinalSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.white,
                        disabledBackgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("다음", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}