import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/features/store/data/repositories/store_repository_impl.dart';
import 'package:frontend/features/consumer/order/presentation/pages/order_page.dart';

class ShopPage extends StatefulWidget {
  final int storeId;
  const ShopPage({Key? key, required this.storeId}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _repo = StoreRepositoryImpl();
  late Future<StoreModel> _storeFuture;

  // 즐겨찾기 상태 변수
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _storeFuture = _repo.getStoreDetail(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<StoreModel>(
          future: _storeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
            if (!snapshot.hasData) {
              return const Center(child: Text('가게 정보가 없습니다.'));
            }

            return _buildBody(context, snapshot.data!);
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
                // 가게 이미지
                Container(
                  width: double.infinity,
                  height: 223,
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // 가게 이름 및 하트 아이콘
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        store.storeName,
                        style: const TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF181C2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        },
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : const Color(0xFF181C2E),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),


                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Divider(color: Color(0xFFA0A5BA), thickness: 1),
                ),

                // 주소 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
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
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E3E5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('네이버지도', style: TextStyle(fontSize: 12, color: Color(0xFF32343E))),
                                SizedBox(width: 4),
                                Icon(Icons.north_east, size: 14, color: Color(0xFF32343E)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 지도 Placeholder
                Container(
                  width: double.infinity,
                  height: 188,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFBF0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF11A94D), width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on, color: Color(0xFF11A94D), size: 40),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 주문하기 버튼 (영업 상태에 따른 비활성화 로직은 유지됨)
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