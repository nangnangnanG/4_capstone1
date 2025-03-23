import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ongi_flutter/styles/app_styles.dart';
import 'sign_up_email.dart';
import 'sign_up_birth_date.dart';
import 'sign_in.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../styles/app_styles.dart';


class SignUpStartPage extends StatefulWidget {
  const SignUpStartPage({Key? key}) : super(key: key);

  @override
  State<SignUpStartPage> createState() => _SignUpStartPageState();
}

class _SignUpStartPageState extends State<SignUpStartPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _currentUser;

  Future<void> _handleSignIn(BuildContext context) async {
    Provider.of<SignUpProvider>(context, listen: false).setProvider("local");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpEmailPage()),
    );
  }

  Future<void> _handleLogIn(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      final user = await _googleSignIn.signIn();
      setState(() {
        _currentUser = user;
      });
      if (_currentUser != null) {
        Provider.of<SignUpProvider>(context, listen: false)
            .setEmail(_currentUser!.email);
        Provider.of<SignUpProvider>(context, listen: false)
            .setProvider("google");
        Provider.of<SignUpProvider>(context, listen: false)
            .setPassword(null);

        print("Provider set to: ${Provider.of<SignUpProvider>(context, listen: false).provider}");

        print('Logged in as: ${_currentUser?.displayName}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUpBirthDatePage()),
        );
      }
    } catch (error) {
      print('Sign-In Error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Container (
  //       width: MediaQuery.of(context).size.width, // 화면 가로 크기
  //       height: MediaQuery.of(context).size.height, // 화면 세로 크기
  //       decoration: BoxDecoration(
  //         image: DecorationImage(
  //           image: AssetImage("assets/signup_background.png"),
  //           fit: BoxFit.cover, // 화면을 꽉 채움
  //         ),
  //       ),
  //       child: Column(
  //         children: [
  //           Spacer(),
  //
  //           Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               ElevatedButton.icon(
  //                 onPressed: () => _handleLogIn(context),
  //                 label: const Text(
  //                   '로그인',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //                 style: ButtonStyles.loginButtonStyle(context),
  //               ),
  //
  //               const SizedBox(height: 15),
  //
  //               ElevatedButton(
  //                 onPressed: _handleGoogleSignIn,
  //                 style: ButtonStyles.loginButtonStyle(context),
  //                 child: Stack(
  //                   alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
  //                   children: [
  //                     Row(
  //                       mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
  //                       children: [
  //                         SizedBox(
  //                           width: 24, // 로고 크기 고정
  //                           height: 24,
  //                           child: Image.asset(
  //                             'assets/logos/google_logo.png',
  //                             fit: BoxFit.cover,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //
  //                     const Text(
  //                       '구글 아이디 로그인',
  //                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                       textAlign: TextAlign.center, // 텍스트 중앙 정렬
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 15),
  //
  //
  //               const SizedBox(height: 15),
  //               GestureDetector(
  //                 onTap: () => _handleSignIn(context),
  //                 child: Text(
  //                   '회원가입',
  //                   style: TextStyle(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                     decoration: TextDecoration.underline, // 밑줄 추가
  //                     decorationColor: Colors.white, // 밑줄 색상 변경 가능
  //                     decorationThickness: 2, // 밑줄 두께 조정
  //                   ),
  //                 ),
  //               )
  //             ],
  //           ),
  //           const SizedBox(height: 50),
  //         ],
  //       ),
  //     )
  //   );
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/signup_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // "온기" 텍스트 추가
          Positioned(
            top: MediaQuery.of(context).size.height * 0.17, // 화면 높이의 10% 지점에 위치
            right: MediaQuery.of(context).size.width * 0.1, // 원하는 위치 조정
            child: Text(
              '온\n기', // 줄바꿈을 사용하여 세로 정렬
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'UnPenheulim',
                height: 1.2, // 글자 간격 조절 가능
              ),
              textAlign: TextAlign.center, // 가운데 정렬
            ),
          ),


          // 버튼 그룹
          Positioned(
            bottom: 50, // 버튼 위치 조정
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleLogIn(context),
                  label: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ButtonStyles.loginButtonStyle(context),
                ),
                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ButtonStyles.loginButtonStyle(context),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              'assets/logos/google_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '구글 아이디 로그인',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => _handleSignIn(context),
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      decorationThickness: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
