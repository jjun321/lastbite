import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 앱 foreground 동안 3분마다 사용자 위치를 갱신하는 전역 싱글톤 서비스.
///
/// 구독은 [currentPosition] (`ValueListenable<Position?>`)로 한다.
/// 앱이 background로 전환되면 타이머를 멈추고, foreground로 돌아오면 즉시
/// 1회 갱신 후 다시 주기를 시작한다.
class LocationTrackingService {
  LocationTrackingService._();

  static final LocationTrackingService instance = LocationTrackingService._();

  static const Duration interval = Duration(minutes: 3);

  final ValueNotifier<Position?> currentPosition = ValueNotifier<Position?>(null);

  Timer? _timer;
  bool _isFetching = false;
  bool _started = false;

  /// 앱 시작 시 한 번만 호출. 권한이 없으면 한 번 요청하고, 그래도 없으면
  /// 타이머를 시작하지 않는다(다음 resume 때 다시 시도).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _tickIfAllowed();
    _scheduleTimer();
  }

  /// 앱이 background로 갈 때 호출.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// 앱이 foreground로 돌아올 때 호출. 즉시 1회 갱신 후 주기 재시작.
  Future<void> resume() async {
    if (!_started) {
      await start();
      return;
    }
    await _tickIfAllowed();
    _scheduleTimer();
  }

  /// 외부에서 즉시 갱신을 트리거하고 싶을 때 사용.
  Future<Position?> refreshNow() async {
    await _tickIfAllowed();
    return currentPosition.value;
  }

  void _scheduleTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tickIfAllowed());
  }

  Future<void> _tickIfAllowed() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentPosition.value = position;
    } catch (e) {
      debugPrint('LocationTrackingService tick error: $e');
    } finally {
      _isFetching = false;
    }
  }
}
