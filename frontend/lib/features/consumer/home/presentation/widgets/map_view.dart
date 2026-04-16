import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

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

  static const NLatLng _defaultCenter = NLatLng(37.5827, 127.0088);

  static const String _myLocationIcon = 'assets/images/icon_mylocation_pin.png';
  static const String _storeIcon = 'assets/images/icon_storelocation_pin.png';
  static const String _recommendIcon = 'assets/images/icon_recommend_pin.png';

  Future<Set<NMarker>> _buildMarkers() async {
    final markers = <NMarker>{};

    final myLocationIconImage = await NOverlayImage.fromAssetImage(_myLocationIcon);
    final storeIconImage = await NOverlayImage.fromAssetImage(_storeIcon);
    final recommendIconImage = await NOverlayImage.fromAssetImage(_recommendIcon);

    // 현재 위치 마커
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

      if (store.storeLat == null || store.storeLon == null) continue;

      final icon = (widget.showAiRecommended && store.isAiRecommended)
          ? recommendIconImage
          : storeIconImage;

      final marker = NMarker(
        id: 'store_$i',
        position: NLatLng(store.storeLat!, store.storeLon!),
        icon: icon,
      );

      marker.setCaption(NOverlayCaption(text: store.storeName));

      markers.add(marker);
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildNaverMap()),
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
      _refreshMarkers();
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
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