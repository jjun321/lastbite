import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/data/store_model.dart';

/// 지도 뷰를 표시하는 위젯.
/// Google Maps API 키가 설정되어 있으면 실제 지도를 표시하고,
/// 미설정이면 placeholder를 보여준다.
///
/// API 키 설정 방법:
/// - Android: android/app/src/main/AndroidManifest.xml 에
///   <meta-data android:name="com.google.android.geo.API_KEY"
///              android:value="YOUR_API_KEY"/> 추가
/// - iOS: ios/Runner/AppDelegate.swift 에
///   GMSServices.provideAPIKey("YOUR_API_KEY") 추가
/// - 또는 이 위젯의 apiKey 파라미터로 전달 (런타임 확인용)

class MapView extends StatefulWidget {
  final List<StoreModel> stores;
  final bool showAiRecommended;
  final VoidCallback? onSelectTap;

  /// Google Maps API 키.
  /// 빈 문자열이면 placeholder를 표시
  final String apiKey;

  const MapView({
    super.key,
    required this.stores,
    this.showAiRecommended = false,
    this.onSelectTap,
    this.apiKey = '',
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;

  /// API 키 유효 여부 — 빈 문자열이 아니면 유효로 간주
  bool get _hasApiKey => widget.apiKey.isNotEmpty;

  /// 기본 카메라 위치 (학교 근처)
  static const LatLng _defaultCenter = LatLng(37.5827, 127.0088);

  /// 가게 목록을 마커로 변환
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (int i = 0; i < widget.stores.length; i++) {
      final store = widget.stores[i];
      if (store.latitude == null || store.longitude == null) continue;

      /// 마커 색상 결정:
      /// - AI 추천 + 표시 활성: 빨강
      /// - 일반 가게: 초록
      /// - 사용자 위치 등: 노랑 (현재는 첫 번째 가게를 노랑으로 표시)
      double hue;
      if (widget.showAiRecommended && store.isAiRecommended) {
        hue = BitmapDescriptor.hueRed;
      } else if (i == 0) {
        hue = BitmapDescriptor.hueYellow;
      } else {
        hue = BitmapDescriptor.hueGreen;
      }

      markers.add(
        Marker(
          markerId: MarkerId('store_$i'),
          position: LatLng(store.latitude!, store.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: store.name, snippet: store.closingTime),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ─── 지도 영역 ───
        Expanded(child: _hasApiKey ? _buildGoogleMap() : _buildPlaceholder()),

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

  /// 실제 Google Maps 위젯
  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
      },
      initialCameraPosition: const CameraPosition(
        target: _defaultCenter,
        zoom: 14.5,
      ),
      markers: _buildMarkers(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
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
                  '지도를 표시하려면\nGoogle Maps API 키를 설정하세요',
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
                    _buildDummyMarker(Colors.yellow.shade700, '내 위치'),
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
