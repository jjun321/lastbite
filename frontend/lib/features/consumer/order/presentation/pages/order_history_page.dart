import 'package:flutter/material.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _repo = OrderRepositoryImpl();
  bool isReservedSelected = true;

  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _repo.getOrders();
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadOrders();
          },
          child: FutureBuilder<List<OrderModel>>(
            future: _ordersFuture,
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
                      const Text('주문 내역을 불러오지 못했습니다.'),
                      TextButton(
                        onPressed: _loadOrders,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }

              final allOrders = snapshot.data ?? [];

              final int totalSavedAmount = allOrders.where((order) => order.orderStatus != 'S04').fold(0, (sum, order) {
                final int orderOriPriceSum = order.items.fold(0, (iSum, item) => iSum + (item.productOriPrice * item.quantity));
                final int savedAmount = orderOriPriceSum - order.totalPrice;
                return sum + (savedAmount > 0 ? savedAmount : 0);
              });

              final displayItems = allOrders.where((o) {
                return isReservedSelected
                    ? o.orderStatus != 'S04'
                    : o.orderStatus == 'S04';
              }).toList();

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildSavingsCard(_formatCurrency(totalSavedAmount)),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          isReservedSelected ? '진행 중인 예약이 없습니다.' : '취소된 내역이 없습니다.',
          style: const TextStyle(fontFamily: 'Sen', color: Color(0xFF6B6E82)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '주문내역',
          style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E)),
        ),
      ),
    );
  }

  Widget _buildSavingsCard(String savings) {
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
                style: TextStyle(fontFamily: 'Sen', fontSize: 20, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$savings원',
            style: const TextStyle(
              fontFamily: 'Sen', fontSize: 36,
              color: Colors.white, fontWeight: FontWeight.bold,
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
            onTap: () {
              setState(() {
                isReservedSelected = true;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildTabItem(
            label: '취소된 주문',
            isSelected: !isReservedSelected,
            onTap: () {
              setState(() {
                isReservedSelected = false;
              });
            },
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
              color: isSelected ? const Color(0xFF4FA55B) : const Color(0xFFE4E4E4),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF4FA55B) : const Color(0xFF1E1E1E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 32, color: Color(0xFFEEF2F6), indent: 24, endIndent: 24,
      ),
      itemBuilder: (context, index) => _buildOrderItem(items[index]),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    final String displayMenuName = order.items.isNotEmpty
        ? (order.items.length > 1
        ? '${order.items[0].productName} 외'
        : order.items[0].productName)
        : '-';

    final totalCount = order.items.fold(0, (sum, i) => sum + i.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          order.storeName,
                          style: const TextStyle(
                            fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#${order.orderId}',
                          style: const TextStyle(
                            fontFamily: 'Sen', fontSize: 14,
                            color: Color(0xFF6B6E82),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ✅ 왼쪽 정렬을 위해 Wrap 또는 Row 설정 변경
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬 고정
                      children: [
                        Flexible( // Expanded 대신 Flexible 사용: 짧으면 콘텐츠만큼만 차지
                          child: Text(
                            displayMenuName,
                            style: const TextStyle(
                              fontFamily: 'Sen', fontSize: 13, fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('|', style: TextStyle(color: Color(0xFFCACCDA))),
                        ),
                        Text(
                          '총 $totalCount개',
                          style: const TextStyle(
                            fontFamily: 'Sen', fontSize: 12, color: Color(0xFF6B6E82),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('|', style: TextStyle(color: Color(0xFFCACCDA))),
                        ),
                        Text(
                          '${_formatCurrency(order.totalPrice)}원',
                          style: const TextStyle(
                            fontFamily: 'Sen', fontSize: 12, color: Color(0xFF6B6E82),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '픽업 ${order.pickupDt.toString().substring(0, 16).replaceAll('T', ' ')}',
                      style: const TextStyle(
                        fontFamily: 'Sen', fontSize: 12, color: Color(0xFF6B6E82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(
                      order: order,
                      isCancelled: order.orderStatus == 'S04',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FA55B),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '주문 상세',
                style: TextStyle(
                  fontFamily: 'Sen', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}