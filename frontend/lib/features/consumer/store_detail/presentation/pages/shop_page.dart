import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/features/store/data/repositories/store_repository_impl.dart';
import 'package:frontend/features/consumer/order/presentation/pages/order_page.dart';
import 'package:frontend/features/consumer/mypage/data/datasources/favorite_api.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/auth_service.dart' show kBaseUrl;

class ShopPage extends StatefulWidget {
  final int storeId;
  const ShopPage({super.key, required this.storeId});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _repo = StoreRepositoryImpl();
  late Future<StoreModel> _storeFuture;

  bool _isFavorite = false;
  bool _isTogglingFavorite = false;

  final FavoriteRemoteDataSource _favoriteApi = FavoriteRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _storeFuture = _repo.getStoreDetail(widget.storeId);
  }

  /// 찜 토글 (백엔드 연동)
  Future<void> _toggleFavorite(StoreModel store) async {
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);

    final newState = !_isFavorite;

    // UI 업데이트
    setState(() => _isFavorite = newState);

    bool success;
    if (newState) {
      success = await _favoriteApi.addFavorite(store.storeId);
    } else {
      success = await _favoriteApi.removeFavorite(store.storeId);
    }

    if (!success) {
      // 실패 시 원상복구
      setState(() => _isFavorite = !newState);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('즐겨찾기 상태 변경에 실패했습니다.')));
      }
    }

    if (mounted) setState(() => _isTogglingFavorite = false);
  }

  /// 네이버 지도 열기
  Future<void> _launchNaverMap(StoreModel store) async {
    // 매장명과 주소를 합치면 검색 정확도가 떨어지므로 주소만으로 검색한다.
    final query = Uri.encodeComponent(store.storeAddress);
    // 외부 브라우저/네이버지도 앱에서 검색 결과 페이지를 열도록 URL 구성
    final url = Uri.parse('https://map.naver.com/p/search/$query');

    // canLaunchUrl 는 Android 11+ 에서 manifest <queries> 가 없으면 false 를 돌려주므로
    // 곧바로 launchUrl 을 시도하고 실패 시에만 SnackBar 를 띄운다.
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('네이버 지도를 열 수 없습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('네이버 지도를 열 수 없습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<StoreModel>(
          future: _storeFuture,
          builder: (context, snapshot) {
            // 로딩 중
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 에러
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text('오류: ${snapshot.error}'),
                    TextButton(
                      onPressed: () => setState(() {
                        _storeFuture = _repo.getStoreDetail(widget.storeId);
                      }),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            // 데이터 없음
            if (!snapshot.hasData) {
              return const Center(child: Text('가게 정보가 없습니다.'));
            }

            // 정상
            final store = snapshot.data!;

            // 처음 로드 시 isFavorite 동기화
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isFavorite != store.isFavorite) {
                setState(() => _isFavorite = store.isFavorite);
              }
            });

            return _buildBody(context, store);
          },
        ),
      ),
    );
  }

  Widget _buildShopImage(StoreModel store) {
    final raw = store.storeImgUrl;
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();

    final url = raw.startsWith('http') ? raw : '$kBaseUrl$raw';
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody(BuildContext context, StoreModel store) {
    return Column(
      children: [
        // 상단 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECF0F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Color(0xFF181C2E),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                store.storeName,
                style: const TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF181C2E),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 가게 이미지
                Container(
                  width: double.infinity,
                  height: 223,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildShopImage(store),
                ),

                // 가게 이름 + 찜 하트
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF181C2E),
                          ),
                        ),
                      ),
                      // 찜 하트 버튼
                      GestureDetector(
                        onTap: () => _toggleFavorite(store),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFBDBDBD),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // 영업 상태
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: store.isClosed || store.isOffToday
                              ? const Color(0xFFFFEEEE)
                              : const Color(0xFFEAFBF0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          store.isOffToday
                              ? '휴무일'
                              : store.isClosed
                              ? '마감'
                              : '영업중',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: store.isClosed || store.isOffToday
                                ? Colors.red
                                : const Color(0xFF11A94D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Divider(color: Color(0xFFA0A5BA), thickness: 1),
                ),

                // 주소
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '주소 ',
                              style: TextStyle(
                                fontFamily: 'Sen',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C2E),
                              ),
                            ),
                            TextSpan(
                              text: store.storeAddress,
                              style: const TextStyle(
                                fontFamily: 'Sen',
                                fontSize: 14,
                                color: Color(0xFF32343E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _launchNaverMap(store),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E3E5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '네이버지도',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF32343E),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.north_east,
                                  size: 14,
                                  color: Color(0xFF32343E),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 실제 네이버 지도
                GestureDetector(
                  onTap: () => _launchNaverMap(store),
                  child: Container(
                    width: double.infinity,
                    height: 188,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF11A94D),
                        width: 1,
                      ),
                    ),
                    child: store.storeLat != null && store.storeLon != null
                        ? NaverMap(
                            options: NaverMapViewOptions(
                              initialCameraPosition: NCameraPosition(
                                target: NLatLng(
                                  store.storeLat!,
                                  store.storeLon!,
                                ),
                                zoom: 15,
                              ),
                              locationButtonEnable: false,
                              scrollGesturesEnable:
                                  false, // 상세페이지에서는 고정된 지도가 가독성이 좋음
                              zoomGesturesEnable: false,
                              consumeSymbolTapEvents:
                                  false, // 클릭 이벤트가 부모(GestureDetector)로 전달되도록
                            ),
                            onMapReady: (controller) {
                              final marker = NMarker(
                                id: 'store_${store.storeId}',
                                position: NLatLng(
                                  store.storeLat!,
                                  store.storeLon!,
                                ),
                                caption: NOverlayCaption(text: store.storeName),
                              );
                              controller.addOverlay(marker);
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  '위치 정보가 없습니다.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 예약하기 버튼
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: store.isClosed || store.isOffToday
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderScreen(
                          storeId: store.storeId,
                          storeName: store.storeName,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FA55B),
              disabledBackgroundColor: const Color(0xFFA0A5BA),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              store.isClosed || store.isOffToday ? '현재 주문 불가' : '예약하기',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
