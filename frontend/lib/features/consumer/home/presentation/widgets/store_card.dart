import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/services/auth_service.dart' show kBaseUrl;

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const StoreCard({super.key, required this.store, this.onTap, this.onFavoriteTap});

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
                  /// 가게 이름 + 찜 아이콘
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