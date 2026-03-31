import 'package:flutter/material.dart';
import 'package:frontend/app/router/app_router.dart';

/// ------------------------------------------------------------
/// 파일명: app.dart
/// 위치: lib/app/app.dart
///
/// 역할:
/// MaterialApp.router 를 설정해서
/// appRouter가 동작하도록 연결한다.
/// ------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Last Bite',
      debugShowCheckedModeBanner: false,

      /// 앱 전체 테마
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard', // 폰트 미설정이면 지워도 됨
      ),

      /// go_router 연결
      routerConfig: appRouter,
    );
  }
}
