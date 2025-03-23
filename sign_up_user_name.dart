import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_phone_verification.dart';
import '../../styles/app_styles.dart';

class SignUpUserNamePage extends StatefulWidget {
  const SignUpUserNamePage({super.key});

  @override
  State<SignUpUserNamePage> createState() => _SignUpUserNamePageState();
}

class _SignUpUserNamePageState extends State<SignUpUserNamePage> {
  final TextEditingController _nickNameController = TextEditingController();
  bool _isNickNameValid = false;

  // 이메일 유효성 검사 함수
  void _validateNickName(String nickname) {
    setState(() {
      _isNickNameValid = nickname.isNotEmpty; // 한 글자 이상이면 true
    });
  }
  // 다음 페이지로 이동
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isNickNameValid) {
      Provider.of<SignUpProvider>(context, listen: false).setUsername(_nickNameController.text);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPhoneVerificationPage()),
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "회원가입",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 56, // 기본 AppBar 높이
      ),

      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "이름",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nickNameController,
              onChanged: _validateNickName, // 이메일 입력값이 변경될 때 유효성 검사 실행
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white, // 입력 필드 배경색
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 5), // 텍스트와 입력 필드 사이 간격 추가

            const SizedBox(height: 30), // 버튼과 간격 추가
            Center(
              child: SizedBox(
                width: 100, // 버튼 크기 조정
                height: 50,
                child: ElevatedButton(
                  onPressed: _isNickNameValid ? () => _goToPasswordPage(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNickNameValid ? Colors.white : Colors.grey, // 활성화 상태 배경색
                    disabledBackgroundColor: Colors.grey[800], // 🔥 비활성화 상태일 때도 회색 유지
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 버튼 모서리 둥글게
                    ),
                  ),
                  child: Text(
                    "다음",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, // 텍스트 색상
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nickNameController.dispose();
    super.dispose();
  }
}
