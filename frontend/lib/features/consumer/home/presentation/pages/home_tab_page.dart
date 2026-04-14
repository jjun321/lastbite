import 'package:flutter/material.dart';
import 'package:frontend/features/consumer/store_detail/presentation/pages/shop_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/data/store_model.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/view_toggle.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/location_preset_bar.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/store_card.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/map_view.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/distance_filter_dialog.dart';

import 'package:frontend/features/consumer/home/data/datasources/store_api.dart';

/// 홈 탭의 실제 콘텐츠를 표시한다.
/// 리스트/지도 토글, 위치 프리셋, 필터, 가게 카드 등을 포함.

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  /// 현재 뷰 모드: true = 리스트, false = 지도
  bool _isListView = true;

  /// AI 추천 표시 여부
  bool _showAiRecommended = false;

  /// 가게 데이터 (찜 토글을 위해 mutable)
  late List<StoreModel> _stores;

  /// 현재 사용자 위치
  Position? _currentPosition;

  /// 위치 로딩 상태
  bool _isLoadingLocation = false;

  /// 매장 데이터 로딩 상태
  bool _isLoadingStores = true;

  /// 현재 선택된 거리 필터 (미터 단위, 0 = 필터 없음)
  int _filterDistance = 0;

  final StoreRemoteDataSource _storeApi = StoreRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _stores = [];
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoadingStores = true);

    final fetchedStores = await _storeApi.getStores();

    setState(() {
      _stores = fetchedStores;
      _isLoadingStores = false;
    });
  }

  // 위치 권한을 확인하고 현재 위치를 가져오는 메서드
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // 권한 요청
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showSnackBar('위치 권한이 거부되었습니다.');
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.');
        }
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

      if (mounted) {
        _showSnackBar(
          '현재 위치: ${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}',
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        _showSnackBar('위치를 가져오는데 실패했습니다: $e');
      }
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

  // 거리 필터 다이얼로그
  Future<void> _showDistanceFilter() async {
    final result = await DistanceFilterDialog.show(
      context,
      currentDistance: _filterDistance,
    );

    if (result != null) {
      setState(() {
        _filterDistance = result;
      });

      // 필터 거리에 따른 안내 메시지
      final label = result == 0
          ? '전체'
          : result >= 1000
          ? '${result ~/ 1000}km'
          : '${result}m';
      if (mounted) {
        _showSnackBar('반경 $label 내 가게를 표시합니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        /// ─── 리스트/지도 토글 ───
        ViewToggle(
          isListView: _isListView,
          onChanged: (isListView) {
            setState(() {
              _isListView = isListView;
            });
          },
        ),

        /// ─── 위치 프리셋 + 필터/AI 버튼 ───
        LocationPresetBar(
          isListView: _isListView,
          isAiActive: _showAiRecommended,
          isLoadingLocation: _isLoadingLocation,
          currentPosition: _currentPosition,
          filterDistance: _filterDistance,
          onPresetTap: _getCurrentLocation,
          onFilterTap: _showDistanceFilter,
          onAiRecommendTap: () {
            setState(() {
              _showAiRecommended = !_showAiRecommended;
            });
          },
        ),

        /// ─── 콘텐츠 영역 ───
        Expanded(child: _isListView ? _buildListView() : _buildMapView()),
      ],
    );
  }

  /// 리스트 뷰 — 가게 카드 리스트
  Widget _buildListView() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stores.isEmpty) {
      return const Center(child: Text("표시할 가게가 없습니다."));
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
                builder: (context) => ShopPage(store: _stores[index]),
              ),
            ).then((_) => _loadStores());
          },
        );
      },
    );
  }

  /// 지도 뷰
  Widget _buildMapView() {
    if (_isLoadingStores) {
      return const Center(child: CircularProgressIndicator());
    }
    return MapView(
      stores: _stores,
      showAiRecommended: _showAiRecommended,
      currentPosition: _currentPosition,
      onSelectTap: () {},
    );
  }
}
