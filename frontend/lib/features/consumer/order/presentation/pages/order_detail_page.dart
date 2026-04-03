import 'package:flutter/material.dart';
import 'package:frontend/data/mock_data.dart';
import 'package:frontend/data/models.dart';

// 소비자 주문 상세/취소 주문 상세 페이지

class OrderDetailScreen extends StatelessWidget {
  final bool isCancelled;
  final Order order;

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
                    // 취소되지 않았을 때만 상단 주문번호 카드 노출
                    if (!isCancelled) _buildOrderNumberCard(order.orderNo),
                    const SizedBox(height: 16),

                    // 주문 일시
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '2026.01.01. 03:22 PM', //데이터에 시간 필드 추가 후 연동
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          color: Color(0xFF6B6E82),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildStoreSummary(),
                    const SizedBox(height: 24),

                    // 주문 메뉴 내역 타이틀
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '주문 메뉴',
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C2E),
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
                    const SizedBox(height: 32),
                    _buildCustomerSection(),
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

  // 주문 메뉴
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
          final bool isLast = item == order.items.last;
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
                          item.menu.name,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF181C2E),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 16,
                          color: const Color(0xFFCACCDA),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${item.quantity}개',
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 12,
                            color: Color(0xFF6B6E82),
                          ),
                        ),
                      ],
                    ),
                    // 개별 품목 총액 (할인가 적용됨)
                    Text(
                      '${item.totalPrice} 원',
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
        }).toList(),
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
              width: 45,
              height: 45,
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
          const SizedBox(width: 16),
          const Text(
            '주문 상세',
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 17,
              color: Color(0xFF181C2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNumberCard(String orderNo) {
    return Center(
      child: Container(
        width: 342,
        height: 159,
        decoration: BoxDecoration(
          color: const Color(0xFF4FA55B),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '주문번호',
              style: TextStyle(
                fontFamily: 'Sen',
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              orderNo,
              style: const TextStyle(
                fontFamily: 'Sen',
                fontSize: 36,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
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
                        Text(
                          myStore.name,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            color: Color(0xFF6B6E82),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 총 갯수 (예: 3개)
                        Text(
                          order.totalCountString,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '|',
                            style: TextStyle(color: Color(0xFFCACCDA)),
                          ),
                        ),
                        // 최종 가격 (예: 15,000 원)
                        Text(
                          order.formattedTotalPrice,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '픽업 ${order.pickupTime}',
                      style: const TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 14,
                        color: Color(0xFF6B6E82),
                      ),
                    ),
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

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 금액',
          style: TextStyle(
            fontFamily: 'Sen',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF181C2E),
          ),
        ),
        const SizedBox(height: 16),
        _buildPriceRow('정가', order.formattedOriginalPrice),
        const SizedBox(height: 8),
        _buildPriceRow(
          '할인액',
          '- ${order.formattedDiscountAmount}',
        ), // 할인액 앞에 '-' 추가 센스!
        const SizedBox(height: 12),
        _buildPriceRow('합계', order.formattedTotalPrice, isTotal: true),
      ],
    );
  }

  // ⭐️ [오류 해결] 누락되었던 _buildPriceRow 메서드 추가
  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF717171),
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : const Color(0xFF828282),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 24),
          const Text(
            '주문자 정보',
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('주문자', currentUser.name),
          const SizedBox(height: 8),
          _buildInfoRow('연락처', currentUser.phoneNumber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF717171),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}
