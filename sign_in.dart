import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/user_provider.dart';  // UserProvider import 추가
import 'package:ongi_flutter/services/api/user_api.dart';
import '../main/main_tab.dart';
import '../../styles/app_styles.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print("🔵 로그인 요청 시작: email=$email");

    setState(() { _isLoading = true; });

    try {
      final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);  // UserProvider 추가

      // 기존 데이터 초기화
      await userProvider.reset();  // 기존 사용자 데이터 초기화

      final response = await UserApi.loginUser(email, password);

      print("🟡 로그인 응답: $response");

      setState(() { _isLoading = false; });

      if (response.containsKey("auth_token")) { // ✅ 로그인 성공
        // 로그인 정보 저장
        signUpProvider.setAuthToken(response["auth_token"]);
        signUpProvider.setLoggedIn(true);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (response.containsKey("user_id")) {
          await prefs.setString("user_id", response["user_id"]);
          print("✅ user_id 저장 완료: ${response["user_id"]}");
        } else {
          print("❌ user_id 없음");
        }

        // 사용자 정보 로드 요청 (중요!)
        print("✅ 사용자 정보 로드 요청");
        await userProvider.loadUserInfo(forceRefresh: true);

        print("✅ 로그인 성공, 메인 화면으로 이동");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainTabPage()),
        );
      } else { // ❌ 로그인 실패
        print("❌ 로그인 실패: ${response["error"] ?? "잘못된 이메일 또는 비밀번호"}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 로그인 실패: ${response["error"] ?? "잘못된 이메일 또는 비밀번호입니다."}")),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; }); // ✅ 예외 발생 시 로딩 해제
      print("❌ 로그인 요청 중 예외 발생: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 네트워크 오류: 로그인할 수 없습니다.")),
      );
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
        title: const Text("로그인", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("이메일", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDecoration()),
            const SizedBox(height: 15),
            const Text("비밀번호", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration()),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn, // ✅ 로그인 요청
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("로그인", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}