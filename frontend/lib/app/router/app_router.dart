import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/auth/presentation/pages/signup_page.dart';
import 'package:frontend/features/auth/presentation/pages/welcome_page.dart';
import 'package:frontend/features/consumer/home/presentation/pages/consumer_home_page.dart';
import 'package:frontend/features/owner/dashboard/presentation/pages/owner_dashboard_page.dart';

/// 앱의 페이지 이동 규칙을 정의한다.
///
/// 사용자가 직접 작성할 순서:
/// 1) go_router 패키지 설치
/// 2) 각 페이지 import
/// 3) GoRouter 객체 생성
/// 4) initialLocation 을 '/welcome' 으로 설정
/// 5) 각 경로(path)에 맞는 페이지 연결

final GoRouter appRouter = GoRouter(
  /// 앱을 처음 켰을 때 가장 먼저 보여줄 경로
  initialLocation: '/welcome',

  routes: [
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ConsumerHomePage(),
    ),
    GoRoute(
      path: '/owner-dashboard',
      builder: (context, state) => const OwnerDashboardScreen(),
    ),
  ],
);
