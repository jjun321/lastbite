import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/services/location_tracking_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 앱 실행 시작점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // 네이버 지도 SDK 초기화 (신규 API - v1.3.1+)
  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '',
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

  // 위치 추적 서비스 시작 (앱 foreground 동안 3분마다 위치 갱신)
  // 권한 요청 등 비동기 처리는 백그라운드로 진행해 앱 시작을 막지 않는다.
  unawaited(LocationTrackingService.instance.start());

  runApp(const MyApp());
}
