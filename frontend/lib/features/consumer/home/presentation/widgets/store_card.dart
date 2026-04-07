import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const StoreCard({
    super.key,
    required this.store,
    this.onTap,
    this.onFavoriteTap,
  });

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
            /// ─── 가게 이미지 영역 (1번 디자인 그대로) ───
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                // 현재 모델에 imageUrl 필드가 없으므로 1번의 아이콘 디자인만 적용
              ),
              child: const Center(
                child: Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ),

            /// ─── 가게 정보 영역 ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 가게 이름 + 찜 아이콘 (변수명: storeName)
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
                      GestureDetector(
                        onTap: onFavoriteTap,
                        child: Icon(
                          store.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: store.isFavorite
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFBDBDBD),
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// 주소 표시 (1번의 카테고리 자리에 주소 연결)
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

                  /// 거리 + 마감 시간 (1번의 별점 디자인 레이아웃 유지)
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined, // 별점 대신 거리 아이콘
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
                        store.todayClose != null
                            ? '${store.todayClose} 마감'
                            : '영업 종료',
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