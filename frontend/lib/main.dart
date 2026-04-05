import 'package:flutter/material.dart';
import 'package:frontend/app/app.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 앱 실행 시작점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 네이버 지도 SDK 초기화 (신규 API - v1.3.1+)
  await FlutterNaverMap().init(
    clientId: 'jju5nju4gc',
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint("========================================");
          debugPrint("네이버 지도 사용량 초과 (message: $message)");
          debugPrint("========================================");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          debugPrint("========================================");
          debugPrint("네이버 지도 인증 실패: $ex");
          debugPrint("========================================");
          break;
      }
    },
  );
  debugPrint("네이버 지도 SDK 초기화 완료");
  runApp(const MyApp());
}
