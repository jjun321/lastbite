import 'package:flutter/material.dart';
import 'package:frontend/features/consumer/store_detail/presentation/pages/shop_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/features/store/data/repositories/store_repository_impl.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/view_toggle.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/location_preset_bar.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/store_card.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/map_view.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/distance_filter_dialog.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  final _repo = StoreRepositoryImpl();

  bool _isListView = true;
  bool _showAiRecommended = false;

  List<StoreModel> _stores = [];
  bool _isLoadingStores = false;
  String? _storeError;

  Position? _currentPosition;
  bool _isLoadingLocation = false;

  /// 현재 선택된 거리 필터 (km 단위, 0 = 필터 없음)
  int _filterDistance = 300; // 기본 반경 3km

  @override
  void initState() {
    super.initState();
    // 시작 시 위치 없이 전체 매장 조회
    _fetchStores();
  }

  // ── API 호출 ──────────────────────────────────────────

  Future<void> _fetchStores({double? lat, double? lon}) async {
    setState(() {
      _isLoadingStores = true;
      _storeError = null;
    });

    try {
      final stores = await _repo.getStores(
        lat: lat,
        lon: lon,
        radius: _filterDistance,
      );
      setState(() {
        _stores = stores;
        _isLoadingStores = false;
      });
    } catch (e, stacktrace) {
      print('❌ 매장 불러오기 실패 에러: $e');
      print('❌ 스택트레이스: $stacktrace');
      setState(() {
        _isLoadingStores = false;
      });
    }
  }

  // ── 위치 관련 ─────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showSnackBar('위치 서비스가 비활성화되어 있습니다.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnackBar('위치 권한이 거부되었습니다.');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showSnackBar('위치 권한이 영구 거부되었습니다. 설정에서 변경해주세요.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // 위치 받으면 주변 매장 다시 조회
      await _fetchStores(lat: position.latitude, lon: position.longitude);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) _showSnackBar('위치를 가져오는데 실패했습니다.');
    }
  }

  // ── 필터 ──────────────────────────────────────────────

  Future<void> _showDistanceFilter() async {
    final result = await DistanceFilterDialog.show(
      context,
      currentDistance: _filterDistance,
    );

    if (result != null) {
      setState(() => _filterDistance = result);

      // 필터 바뀌면 매장 다시 조회
      await _fetchStores(
        lat: _currentPosition?.latitude,
        lon: _currentPosition?.longitude,
      );

      final label = result == 0
          ? '전체'
          : result >= 1000
          ? '${result ~/ 1000}km'
          : '${result}m';
      if (mounted) _showSnackBar('반경 $label 내 가게를 표시합니다.');
    }
  }

  // ── AI 추천 토글 ───────────────────────────────────────

  Future<void> _onAiRecommendTap() async {
    if (_showAiRecommended) {
      setState(() {
        _showAiRecommended = false;
        _stores = _stores
            .map(
              (s) => s.isAiRecommended ? s.copyWith(isAiRecommended: false) : s,
            )
            .toList();
      });
      return;
    }

    try {
      final recommendedIds = await _repo.getRecommendedStoreIds(topN: 10);

      // 반경 내 매장 목록(_stores)에 포함된 추천 매장 중 score 1순위 1개 선택
      final storeIdSet = _stores.map((s) => s.storeId).toSet();
      final matchedId = recommendedIds.firstWhere(
        storeIdSet.contains,
        orElse: () => -1,
      );

      if (matchedId == -1) {
        if (mounted) _showSnackBar('주변에 추천 매장이 존재하지 않습니다.');
        return;
      }

      setState(() {
        _showAiRecommended = true;
        _stores = _stores
            .map(
              (s) => s.storeId == matchedId
                  ? s.copyWith(isAiRecommended: true)
                  : (s.isAiRecommended
                        ? s.copyWith(isAiRecommended: false)
                        : s),
            )
            .toList();
      });
    } catch (e) {
      print('❌ 추천 매장 조회 실패: $e');
      if (mounted) _showSnackBar('추천 매장을 불러오지 못했습니다.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        ViewToggle(
          isListView: _isListView,
          onChanged: (isListView) => setState(() => _isListView = isListView),
        ),
        LocationPresetBar(
          isListView: _isListView,
          isAiActive: _showAiRecommended,
          isLoadingLocation: _isLoadingLocation,
          currentPosition: _currentPosition,
          filterDistance: _filterDistance,
          onPresetTap: _getCurrentLocation,
          onFilterTap: _showDistanceFilter,
          onAiRecommendTap: _onAiRecommendTap,
        ),
        Expanded(
          child: _isLoadingStores
              ? const Center(child: CircularProgressIndicator())
              : _storeError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(_storeError!),
                      TextButton(
                        onPressed: () => _fetchStores(
                          lat: _currentPosition?.latitude,
                          lon: _currentPosition?.longitude,
                        ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _isListView
              ? _buildListView()
              : _buildMapView(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_stores.isEmpty) {
      return const Center(child: Text('주변에 매장이 없습니다.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        return StoreCard(
          store: _stores[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShopPage(storeId: _stores[index].storeId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }
    return MapView(
      stores: _stores,
      showAiRecommended: _showAiRecommended,
      currentPosition: _currentPosition,
      onSelectTap: () {
        // TODO: 선택된 마커의 storeId로 교체
        if (_stores.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopPage(storeId: _stores[0].storeId),
            ),
          );
        }
      },
    );
  }
}
