import 'package:flutter/material.dart';
import 'package:frontend/data/models.dart';

// 점주 상세보기 페이지

class OwnerOrderDetailScreen extends StatelessWidget {
  final Order order;

  const OwnerOrderDetailScreen({Key? key, required this.order})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 31, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFECF0F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF181C2E),
              ),
            ),
          ),
        ),
        title: const Text(
          '주문 상세',
          style: TextStyle(
            fontFamily: 'Sen',
            color: Color(0xFF181C2E),
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '2026.01.01. 03:22 PM',
              style: TextStyle(
                fontFamily: 'Sen',
                fontSize: 14,
                color: Color(0xFF6B6E82),
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionDivider(),

            _buildMenuSummary(),

            _buildDetailItemsBox(),

            const SizedBox(height: 30),
            _buildPaymentSection(),

            const SizedBox(height: 30),
            _buildSectionDivider(),

            _buildCustomerInfoSection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF98A8B8),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.representativeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF181C2E),
                      ),
                    ),
                    Text(
                      order.orderNo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6E82),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.totalCountString} | ${order.price}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181C2E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '픽업: ${order.pickupTime}',
                  style: const TextStyle(
                    color: Color(0xFF6B6E82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: order.items.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          bool isLast = idx == order.items.length - 1;

          return _buildItemRow(
            item.menu.name,
            '${item.quantity}개',
            '${(item.menu.originalPrice * (1 - item.menu.discountRate / 100)).toInt() * item.quantity} 원',
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(
    String name,
    String qty,
    String price, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF181C2E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFFCACCDA),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    qty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6E82),
                    ),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF828282),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFEEF2F6)),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 금액',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF181C2E),
          ),
        ),
        const SizedBox(height: 16),

        // 전체 정가 (할인 전)
        _buildPriceRow('정가', order.formattedOriginalPrice),

        // 총 할인액
        _buildPriceRow('할인액', order.formattedDiscountAmount),

        // 최종 합계 (실 결제액)
        _buildPriceRow('합계', order.formattedTotalPrice, isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF717171)),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : const Color(0xFF828282),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '주문자 정보',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF181C2E),
          ),
        ),
        const SizedBox(height: 16),

        // 임시로 고정값
        const _buildInfoRow('주문자', '김한성'),
        const _buildInfoRow('연락처', '010-1234-5678'),
      ],
    );
  }

  Widget _buildSectionDivider() =>
      const Divider(height: 1, color: Color(0xFFEEF2F6));
}

class _buildInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _buildInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF717171)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E1E)),
          ),
        ],
      ),
    );
  }
}
