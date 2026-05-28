import 'package:flutter/material.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/services/location_tracking_service.dart';

/// ------------------------------------------------------------
/// 파일명: app.dart
/// 위치: lib/app/app.dart
///
/// 역할:
/// MaterialApp.router 를 설정해서
/// appRouter가 동작하도록 연결한다.
///
/// 추가로 앱 lifecycle을 관찰하여 위치 추적 서비스를
/// background 시 pause, foreground 시 resume 한다.
/// ------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        LocationTrackingService.instance.resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        LocationTrackingService.instance.pause();
        break;
    }
  }

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
