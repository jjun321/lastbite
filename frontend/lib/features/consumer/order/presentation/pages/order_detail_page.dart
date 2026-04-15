import 'package:flutter/material.dart';
import 'package:frontend/features/order/data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  final bool isCancelled;

  const OrderDetailScreen({
    Key? key,
    required this.order,
    this.isCancelled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCancelled) _buildOrderNumberCard('#${order.orderId}'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        order.orderDt.toString().substring(0, 16),
                        style: const TextStyle(
                          fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStoreSummary(),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '주문 메뉴',
                        style: TextStyle(
                          fontFamily: 'Sen', fontSize: 14,
                          fontWeight: FontWeight.w700, color: Color(0xFF181C2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuDetailSection(),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPaymentSection(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 45, height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFECF0F4), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF181C2E)),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '주문 상세',
            style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNumberCard(String orderNo) {
    return Center(
      child: Container(
        width: 342, height: 159,
        decoration: BoxDecoration(
          color: const Color(0xFF4FA55B),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('주문번호',
                style: TextStyle(fontFamily: 'Sen', fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            Text(orderNo,
                style: const TextStyle(fontFamily: 'Sen', fontSize: 36, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSummary() {
    final totalCount = order.items.fold(0, (sum, i) => sum + i.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF98A8B8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.storeName,
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('#${order.orderId}',
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82),
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('총 $totalCount개',
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('|', style: TextStyle(color: Color(0xFFCACCDA))),
                        ),
                        Text('${order.totalPrice}원',
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('픽업 ${order.pickupDt.toString().substring(0, 16)}',
                        style: const TextStyle(
                            fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
        ],
      ),
    );
  }

  Widget _buildMenuDetailSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: order.items.map((item) {
          final isLast = item == order.items.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(item.productName,
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700,
                                color: Color(0xFF181C2E))),
                        const SizedBox(width: 14),
                        Container(width: 1, height: 16, color: const Color(0xFFCACCDA)),
                        const SizedBox(width: 14),
                        Text('${item.quantity}개',
                            style: const TextStyle(
                                fontFamily: 'Sen', fontSize: 12, color: Color(0xFF6B6E82))),
                      ],
                    ),
                    Text('${item.subtotal}원',
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 14, color: Color(0xFF828282))),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFEEF2F6)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSection() {
    // 원가 합계
    final originalTotal = order.items.fold(
        0, (sum, i) => sum + (i.productOriPrice * i.quantity));
    final discount = originalTotal - order.totalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('결제 금액',
            style: TextStyle(
                fontFamily: 'Sen', fontWeight: FontWeight.bold,
                fontSize: 14, color: Color(0xFF181C2E))),
        const SizedBox(height: 16),
        _buildPriceRow('정가', '$originalTotal원'),
        const SizedBox(height: 8),
        _buildPriceRow('할인액', '- ${discount}원'),
        const SizedBox(height: 12),
        _buildPriceRow('합계', '${order.totalPrice}원', isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF717171))),
        Text(price,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : const Color(0xFF828282))),
      ],
    );
  }
}