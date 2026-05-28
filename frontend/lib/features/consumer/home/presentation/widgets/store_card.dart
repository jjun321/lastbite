import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/services/auth_service.dart' show kBaseUrl;

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onTap;
  final bool isHotDeal;

  const StoreCard({
    super.key,
    required this.store,
    this.onTap,
    this.isHotDeal = false,
  });

  Widget _buildStoreImage() {
    final raw = store.storeImgUrl;
    if (raw == null || raw.isEmpty) return _imagePlaceholder();

    final url = raw.startsWith('http') ? raw : '$kBaseUrl$raw';
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFE0E0E0),
    child: const Center(
      child: Icon(
        Icons.storefront_outlined,
        size: 48,
        color: Color(0xFFBDBDBD),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ─── 가게 이미지 영역 ───
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _buildStoreImage(),
              ),
            ),

            /// ─── 가게 정보 영역 ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 가게 이름 + 핫딜 배지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHotDeal)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFF6D3B),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '마감 할인 핫딜!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6D3B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  /// 주소
                  Text(
                    store.storeAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  /// 거리 + 마감 시간
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.distanceKm != null
                            ? '${store.distanceKm!.toStringAsFixed(1)}km'
                            : '거리 정보 없음',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        store.isOffToday
                            ? '휴무일'
                            : store.isClosed
                            ? '영업 종료'
                            : store.todayClose != null
                            ? '${store.todayClose} 마감'
                            : '영업중',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}