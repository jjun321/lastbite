import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

/// 점주용 판매 관리 상품 카드 위젯
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isSoldOut;
  final VoidCallback onEdit;
  final VoidCallback onSoldOut;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSoldOut,
    required this.onEdit,
    required this.onSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    final oriPrice = product['product_ori_price'] ?? 0;
    final disPrice = product['product_dis_price'] ?? 0;
    final rate = product['discount_rate'] ?? 0;
    final qty = product['quantity'] ?? 0;
    final imgUrl = product['img_url'] as String?;

    return Opacity(
      opacity: isSoldOut ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지 (카드 상단, 둥근 모서리)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imgUrl != null
                        ? Image.network(
                            imgUrl.startsWith('http')
                                ? imgUrl
                                : '$kBaseUrl$imgUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(
                                Icons.fastfood_outlined,
                                size: 36,
                                color: Color(0xFFBBBBBB),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(
                              Icons.fastfood_outlined,
                              size: 36,
                              color: Color(0xFFBBBBBB),
                            ),
                          ),
                    // 품절 뱃지
                    if (isSoldOut)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF555555,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '품절',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 하단 정보 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품명 + 수정/삭제 버튼
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['product_name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onEdit,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onSoldOut,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 판매가 + 수량
                  Row(
                    children: [
                      Text(
                        '${_format(disPrice)} 원',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$qty개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 원가 (취소선) + 할인율
                  Row(
                    children: [
                      Text(
                        '${_format(oriPrice)}원',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFAAAAAA),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      if (rate > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$rate%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE57C00),
                          ),
                        ),
                      ],
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

  String _format(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
