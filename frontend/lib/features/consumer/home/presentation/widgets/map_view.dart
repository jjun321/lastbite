import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  final List<StoreModel> stores;
  final bool showAiRecommended;
  final VoidCallback? onSelectTap;
  final void Function(int storeId)? onMarkerTap; // 마커 탭 시 storeId 전달
  final Position? currentPosition;
  final Set<int> hotDealStoreIds; // 핫딜 보유 매장 ID 집합

  const MapView({
    super.key,
    required this.stores,
    this.showAiRecommended = false,
    this.onSelectTap,
    this.onMarkerTap,
    this.currentPosition,
    this.hotDealStoreIds = const {},
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  NaverMapController? _mapController;

  static const NLatLng _defaultCenter = NLatLng(37.5827, 127.0088);

  static const String _storeIcon = 'assets/images/icon_storelocation_pin.png';
  static const String _recommendIcon = 'assets/images/icon_recommend_pin.png';

  Future<Set<NMarker>> _buildMarkers() async {
    final markers = <NMarker>{};

    final storeIconImage = await NOverlayImage.fromAssetImage(_storeIcon);
    final recommendIconImage = await NOverlayImage.fromAssetImage(
      _recommendIcon,
    );

    for (int i = 0; i < widget.stores.length; i++) {
      final store = widget.stores[i];

      if (store.storeLat == null || store.storeLon == null) continue;

      // 핫딜 매장 → 빨간 마커, AI 추천 → 추천 마커, 그 외 → 기본
      NOverlayImage icon;
      if (widget.hotDealStoreIds.contains(store.storeId)) {
        // 핫딜 매장은 빨간색 마커 — NMarker의 iconTintColor를 활용하여 빨간색 처리
        icon = storeIconImage;
      } else if (widget.showAiRecommended && store.isAiRecommended) {
        icon = recommendIconImage;
      } else {
        icon = storeIconImage;
      }

      final marker = NMarker(
        id: 'store_$i',
        position: NLatLng(store.storeLat!, store.storeLon!),
        icon: icon,
      );

      // 핫딜 매장은 빨간색 틴트 적용
      if (widget.hotDealStoreIds.contains(store.storeId)) {
        marker.setIconTintColor(const Color(0xFFE53935));
      }

      marker.setCaption(NOverlayCaption(text: store.storeName));

      // 마커 탭 이벤트 — 매장 상세 페이지로 이동
      marker.setOnTapListener((overlay) {
        widget.onMarkerTap?.call(store.storeId);
      });

      markers.add(marker);
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildNaverMap()),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 위치 변경 시 카메라 이동
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
    }

    // 핫딜 스토어 ID가 바뀌거나 매장 목록이 바뀌면 마커 새로고침
    _refreshMarkers();
  }

  Future<void> _refreshMarkers() async {
    if (_mapController == null) return;
    final markers = await _buildMarkers();
    _mapController!.clearOverlays();
    _mapController!.addOverlayAll(markers);
  }

  Widget _buildNaverMap() {
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
        final markers = await _buildMarkers();
        controller.addOverlayAll(markers);
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
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
