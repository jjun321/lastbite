import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/features/consumer/home/presentation/pages/store_model.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/view_toggle.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/location_preset_bar.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/store_card.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/map_view.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/distance_filter_dialog.dart';

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

  /// 현재 선택된 거리 필터 (미터 단위, 0 = 필터 없음)
  int _filterDistance = 0;

  /// ──────────────────────────────────────────────
  /// Google Maps API 키 설정
  /// ──────────────────────────────────────────────
  /// 실제 지도를 사용하려면 아래 값을 Google Maps API 키로 변경하세요.
  /// 빈 문자열('')이면 placeholder 지도가 표시됩니다.
  ///
  /// API 키 발급: https://console.cloud.google.com/
  /// 1. Google Cloud Console에서 프로젝트 생성
  /// 2. Maps SDK for Android / iOS 활성화
  /// 3. API 키 생성 후 아래에 입력
  ///
  /// 추가로 플랫폼별 설정도 필요합니다:
  /// - Android: android/app/src/main/AndroidManifest.xml
  ///   <meta-data android:name="com.google.android.geo.API_KEY"
  ///              android:value="YOUR_API_KEY"/>
  /// - iOS: ios/Runner/AppDelegate.swift
  ///   GMSServices.provideAPIKey("YOUR_API_KEY")
  /// ──────────────────────────────────────────────
  static const String _googleMapsApiKey = '';

  @override
  void initState() {
    super.initState();
    _stores = List.from(dummyStores);
  }

  // ═══════════════════════════════════════════════
  // 위치 서비스 관련 메서드
  // ═══════════════════════════════════════════════

  /// 위치 권한을 확인하고 현재 위치를 가져온다
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1) 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 2) 위치 권한 확인
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

      // 3) 현재 위치 가져오기
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

  // ═══════════════════════════════════════════════
  // 찜(Favorite) 토글
  // ═══════════════════════════════════════════════

  void _toggleFavorite(int index) {
    setState(() {
      _stores[index] = _stores[index].copyWith(
        isFavorite: !_stores[index].isFavorite,
      );
    });
  }

  // ═══════════════════════════════════════════════
  // 거리 필터 다이얼로그
  // ═══════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════
  // 빌드
  // ═══════════════════════════════════════════════

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
        Expanded(
          child: _isListView ? _buildListView() : _buildMapView(),
        ),
      ],
    );
  }

  /// 리스트 뷰 — 가게 카드 리스트
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        return StoreCard(
          store: _stores[index],
          onTap: () {
            // TODO: 가게 상세 페이지로 이동
          },
          onFavoriteTap: () => _toggleFavorite(index),
        );
      },
    );
  }

  /// 지도 뷰
  Widget _buildMapView() {
    return MapView(
      stores: _stores,
      showAiRecommended: _showAiRecommended,
      apiKey: _googleMapsApiKey,
      onSelectTap: () {
        // TODO: 가게 선택 로직
      },
    );
  }
}
