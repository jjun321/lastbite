import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/features/store/data/repositories/store_repository_impl.dart';
import 'package:frontend/features/consumer/order/presentation/pages/order_page.dart';
import 'package:frontend/features/consumer/mypage/data/datasources/favorite_api.dart';

class ShopPage extends StatefulWidget {
  final int storeId;
  const ShopPage({Key? key, required this.storeId}) : super(key: key);

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
                // 가게 이미지 (추후 연결)
                Container(
                  width: double.infinity,
                  height: 223,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                        child: _isTogglingFavorite
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFEF5350),
                                ),
                              )
                            : Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
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
                          onTap: () {
                            // 네이버지도 연결 (추후)
                          },
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

                // 지도 placeholder
                Container(
                  width: double.infinity,
                  height: 188,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFBF0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF11A94D),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF11A94D),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 주문하기 버튼
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
              store.isClosed || store.isOffToday ? '현재 주문 불가' : '주문하기',
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
