import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/sign_up_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/artifact_provider.dart';
import 'screens/auth/sign_up_start.dart';
import 'screens/main/main_tab.dart';
import '../../styles/app_styles.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(OnGiApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

class OnGiApp extends StatelessWidget {
  final bool isLoggedIn;
  const OnGiApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final signUpProvider = SignUpProvider();
            signUpProvider.loadAuthToken();
            return signUpProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final userProvider = UserProvider();
            // 앱 시작 시에만 사용자 정보 로드
            // 로그인/회원가입 후에는 해당 화면에서 직접 loadUserInfo() 호출
            if (isLoggedIn) {
              print("✅ 앱 시작 시 로그인된 상태 감지: 사용자 정보 로드 예약");
              // 약간의 지연 후 사용자 정보 로드 (UI가 렌더링된 후)
              Future.microtask(() async {
                try {
                  await userProvider.loadUserInfo(forceRefresh: true);
                  print("✅ 앱 시작 시 사용자 정보 로드 완료");
                } catch (e) {
                  print("❌ 앱 시작 시 사용자 정보 로드 실패: $e");
                }
              });
            } else {
              print("✅ 앱 시작 시 로그인되지 않은 상태 감지");
            }
            return userProvider;
          },
        ),
        // FeedProvider 추가
        ChangeNotifierProvider(
          create: (_) => FeedProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArtifactProvider(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primarySwatch,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(backgroundColor: Colors.white),
          useMaterial3: true,
        ),
        home: isLoggedIn ? MainTabPage() : SignUpStartPage(),
      ),
    );
  }
}