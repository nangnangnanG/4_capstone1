import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import 'sign_up_user_name.dart';
import '../../styles/app_styles.dart';

class SignUpGenderPage extends StatefulWidget {
  const SignUpGenderPage({super.key});

  @override
  State<SignUpGenderPage> createState() => _SignUpGenderPageState();
}

class _SignUpGenderPageState extends State<SignUpGenderPage> {
  String? _selectedGender;
  bool _isGenderSelected = false;

  // 이메일 유효성 검사 함수
  void _onGenderSelected(String? gender) {
    setState(() {
      _selectedGender = gender;
      _isGenderSelected = gender != null; // 성별이 선택되었으면 버튼 활성화
    });
  }

  // 한글 성별을 영어로 변환하는 함수
  String _convertGender(String koreanGender) {
    switch (koreanGender) {
      case "남자": return "male";
      case "여자": return "female";
      case "정의되지 않음": return "non-binary";
      case "기타": return "other";
      case "말하고 싶지 않음": return "prefer not to say";
      default: return "prefer not to say";
    }
  }

  // 다음 페이지로 이동
  Future<void> _goToPasswordPage(BuildContext context) async {
    if (_isGenderSelected) {
      // 한글 성별을 영어로 변환하여 저장
      Provider.of<SignUpProvider>(context, listen: false).setGender(_convertGender(_selectedGender!));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpUserNamePage()),
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
              "성별",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 60, // <-- 날짜 입력 필드와 동일한 높이
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), // <-- 내부 패딩 조정 (날짜 입력 필드와 동일)
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    items: ["남자", "여자", "정의되지 않음", "기타", "말하고 싶지 않음"].map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: const TextStyle(fontSize: 16), // <-- 리스트 아이템 폰트 크기 맞춤
                        ),
                      );
                    }).toList(),
                    onChanged: _onGenderSelected,
                    isExpanded: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30), // 버튼과 간격 추가
            Center(
              child: SizedBox(
                width: 100, // 버튼 크기 조정
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenderSelected ? () => _goToPasswordPage(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGenderSelected ? Colors.white : Colors.grey, // 활성화 상태 배경색
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
}
