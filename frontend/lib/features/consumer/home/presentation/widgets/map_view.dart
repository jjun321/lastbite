import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
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
  final Position? currentPosition;

  const MapView({
    super.key,
    required this.stores,
    this.showAiRecommended = false,
    this.onSelectTap,
    this.currentPosition,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  NaverMapController? _mapController;

  /// 기본 카메라 위치 (학교 근처)
  static const NLatLng _defaultCenter = NLatLng(37.5827, 127.0088);

  /// 커스텀 마커 아이콘 (에셋 이미지)
  static const String _myLocationIcon = 'assets/images/icon_mylocation_pin.png';
  static const String _storeIcon = 'assets/images/icon_storelocation_pin.png';
  static const String _recommendIcon = 'assets/images/icon_recommend_pin.png';

  /// 가게 목록을 Naver Map 마커 Set으로 변환
  Future<Set<NMarker>> _buildMarkers() async {
    final markers = <NMarker>{};

    // 커스텀 아이콘 이미지 로드
    final myLocationIconImage =
        await NOverlayImage.fromAssetImage(_myLocationIcon);
    final storeIconImage =
        await NOverlayImage.fromAssetImage(_storeIcon);
    final recommendIconImage =
        await NOverlayImage.fromAssetImage(_recommendIcon);

    // 현재 위치 마커 추가
    if (widget.currentPosition != null) {
      final myLocationMarker = NMarker(
        id: 'my_location',
        position: NLatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        icon: myLocationIconImage,
      );
      myLocationMarker.setCaption(NOverlayCaption(text: '내 위치'));
      markers.add(myLocationMarker);
    }

    for (int i = 0; i < widget.stores.length; i++) {
      final store = widget.stores[i];
      if (store.latitude == null || store.longitude == null) continue;

      // AI 추천 여부에 따라 아이콘 결정
      final icon = (widget.showAiRecommended && store.isAiRecommended)
          ? recommendIconImage
          : storeIconImage;

      final marker = NMarker(
        id: 'store_$i',
        position: NLatLng(store.latitude!, store.longitude!),
        icon: icon,
      );

      /// 마커 캡션 설정
      marker.setCaption(NOverlayCaption(text: store.name));

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

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 현재 위치가 새로 들어왔을 때 카메라 이동 및 마커 갱신
    if (widget.currentPosition != oldWidget.currentPosition &&
        widget.currentPosition != null &&
        _mapController != null) {
      final pos = widget.currentPosition!;
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(pos.latitude, pos.longitude),
          zoom: 15,
        ),
      );
      // 마커 전체 갱신 (비동기)
      _refreshMarkers();
    }
  }

  /// 마커를 비동기로 다시 빌드하여 지도에 반영
  Future<void> _refreshMarkers() async {
    if (_mapController == null) return;
    final markers = await _buildMarkers();
    _mapController!.clearOverlays();
    _mapController!.addOverlayAll(markers);
  }

  /// 실제 Naver Maps 위젯
  Widget _buildNaverMap() {
    // 초기 카메라 위치: 현재 위치가 있으면 그곳, 없으면 기본값
    final initialTarget = widget.currentPosition != null
        ? NLatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : _defaultCenter;

    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: initialTarget, zoom: 15),
        locationButtonEnable: true,
      ),
      onMapReady: (controller) async {
        _mapController = controller;

        /// 마커 추가 (비동기 아이콘 로드)
        final markers = await _buildMarkers();
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
