import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:frontend/features/consumer/home/presentation/pages/store_model.dart';

/// 지도 뷰를 표시하는 위젯.
/// Naver Maps API 키가 설정되어 있으면 실제 지도를 표시하고,
/// 미설정이면 placeholder를 보여준다.
///
/// API 키 설정 방법:
/// - Android: android/app/src/main/AndroidManifest.xml 에
///   <meta-data android:name="com.naver.maps.map.CLIENT_ID"
///              android:value="YOUR_CLIENT_ID"/> 추가
/// - iOS: ios/Runner/AppDelegate.swift 에z
///   NaverMapSdk.instance.initialize(clientId: "YOUR_CLIENT_ID") 추가
/// - main.dart 에서 NaverMapSdk.instance.initialize(clientId: '...') 호출 필수

class MapView extends StatefulWidget {
  final List<StoreModel> stores;
  final bool showAiRecommended;
  final VoidCallback? onSelectTap;

  const MapView({
    super.key,
    required this.stores,
    this.showAiRecommended = false,
    this.onSelectTap,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  NaverMapController? _mapController;

  /// 기본 카메라 위치 (학교 근처)
  static const NLatLng _defaultCenter = NLatLng(37.5827, 127.0088);

  /// 가게 목록을 Naver Map 마커 Set으로 변환
  Set<NMarker> _buildMarkers() {
    final markers = <NMarker>{};

    for (int i = 0; i < widget.stores.length; i++) {
      final store = widget.stores[i];
      if (store.latitude == null || store.longitude == null) continue;

      final marker = NMarker(
        id: 'store_$i',
        position: NLatLng(store.latitude!, store.longitude!),
      );

      /// 마커 캡션 설정
      marker.setCaption(NOverlayCaption(text: store.name));

      /// 마커 색상 결정:
      /// - AI 추천 + 표시 활성: 빨강
      /// - 내 현재 위치: 파랑
      /// - 일반 가게: 초록
      if (widget.showAiRecommended && store.isAiRecommended) {
        marker.setIconTintColor(Colors.red);
      } else if (i == 0) {
        marker.setIconTintColor(Colors.yellow);
      } else {
        marker.setIconTintColor(Colors.green);
      }

      markers.add(marker);
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ─── 지도 영역 ───
        Expanded(child: _buildNaverMap()),

        /// ─── 선택하기 버튼 ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onSelectTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FA75A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '선택하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 실제 Naver Maps 위젯
  Widget _buildNaverMap() {
    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: _defaultCenter,
          zoom: 14.5,
        ),
        locationButtonEnable: false,
      ),
      onMapReady: (controller) {
        _mapController = controller;

        /// 마커 추가
        final markers = _buildMarkers();
        controller.addOverlayAll(markers);
      },
    );
  }

  /// API 키가 없을 때 보여줄 placeholder
  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          /// 격자무늬 배경으로 지도 느낌
          CustomPaint(size: Size.infinite, painter: _GridPainter()),

          /// 안내 텍스트
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  '지도를 표시하려면\nNaver Maps API 키를 설정하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AndroidManifest.xml 또는\nAppDelegate.swift에 키를 추가하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 더미 마커들 표시
                Wrap(
                  spacing: 12,
                  children: [
                    _buildDummyMarker(Colors.green, '일반 가게'),
                    _buildDummyMarker(Colors.yellow, '내 위치'),
                    _buildDummyMarker(Colors.red, 'AI 추천'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyMarker(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// placeholder 배경에 격자무늬를 그리는 CustomPainter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
