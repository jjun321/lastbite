import 'package:flutter/material.dart';
import 'package:frontend/data/mock_data.dart';
import 'package:frontend/data/models.dart';
import 'order_detail_page.dart';

// 소비자 주문내역 예약/취소 페이지

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool isReservedSelected = true;

  @override
  Widget build(BuildContext context) {
    final List<Order> displayItems = orderList.where((order) {
      return isReservedSelected ? !order.isCancelled : order.isCancelled;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSavingsCard(),
                    const SizedBox(height: 24),
                    _buildTabButtons(),
                    const SizedBox(height: 16),
                    displayItems.isEmpty
                        ? _buildEmptyState()
                        : _buildOrderList(displayItems),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Text(
        isReservedSelected ? '진행 중인 예약이 없습니다.' : '취소된 내역이 없습니다.',
        style: const TextStyle(fontFamily: 'Sen', color: Color(0xFF6B6E82)),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '주문내역',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 17,
            color: Color(0xFF181C2E),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      width: double.infinity,
      height: 159,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF4FA55B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.paid_outlined, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'LastBite으로 절약한 금액',
                style: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${currentUser.totalSavings ?? "0"}원',
            style: const TextStyle(
              fontFamily: 'Sen',
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildTabItem(
            label: '예약 및 확정',
            isSelected: isReservedSelected,
            onTap: () => setState(() => isReservedSelected = true),
          ),
          const SizedBox(width: 12),
          _buildTabItem(
            label: '취소된 주문',
            isSelected: !isReservedSelected,
            onTap: () => setState(() => isReservedSelected = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAFBF0) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4FA55B)
                  : const Color(0xFFE4E4E4),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF4FA55B)
                    : const Color(0xFF1E1E1E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(
        height: 32,
        color: Color(0xFFEEF2F6),
        indent: 24,
        endIndent: 24,
      ),
      itemBuilder: (context, index) {
        final order = items[index];
        return _buildOrderItem(order);
      },
    );
  }

  Widget _buildOrderItem(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          order.representativeName,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '|',
                            style: TextStyle(color: Color(0xFFCACCDA)),
                          ),
                        ),
                        Text(
                          order.totalCountString,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 12,
                            color: Color(0xFF6B6E82),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '|',
                            style: TextStyle(color: Color(0xFFCACCDA)),
                          ),
                        ),
                        Text(
                          order.price,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 12,
                            color: Color(0xFF6B6E82),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '픽업 ${order.pickupTime}',
            style: const TextStyle(
              fontFamily: 'Sen',
              fontSize: 14,
              color: Color(0xFF6B6E82),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Column(
      children: [
        _buildSingleButton('주문 상세', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                order: order,
                isCancelled: order.isCancelled,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSingleButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4FA55B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
