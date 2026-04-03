import 'package:flutter/material.dart';
import 'package:frontend/data/store_model.dart';

/// 홈 화면 리스트 뷰에서 가게 하나를 표현하는 카드 위젯.
/// 이미지, 이름, 카테고리 태그, 별점, 마감 시간, 찜 아이콘을 표시한다.

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
            /// ─── 가게 이미지 영역 ───
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: store.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(store.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: store.imageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 48,
                        color: Color(0xFFBDBDBD),
                      ),
                    )
                  : null,
            ),

            /// ─── 가게 정보 영역 ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 가게 이름 + 찜 아이콘
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
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

                  /// 카테고리 태그
                  Text(
                    store.categories.join(' | '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// 별점 + 마감 시간
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        store.closingTime,
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
