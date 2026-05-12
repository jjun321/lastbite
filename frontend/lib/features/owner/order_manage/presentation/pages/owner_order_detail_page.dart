import 'package:flutter/material.dart';
import 'package:frontend/features/owner/order_manage/data/models/owner_order_model.dart';
import 'package:frontend/services/order_service.dart';
import 'package:intl/intl.dart';

class OwnerOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OwnerOrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OwnerOrderDetailScreen> createState() => _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends State<OwnerOrderDetailScreen> {
  final OrderService _orderService = OrderService();
  OwnerOrderModel? _orderDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final result = await _orderService.fetchOrderDetail(widget.orderId);
      setState(() {
        _orderDetail = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("상세정보 로딩 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  // 시간 포맷팅 함수 (T, Z 제거 및 가독성 향상)
  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy.MM.dd. hh:mm a').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4FA55B))),
      );
    }

    if (_orderDetail == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("주문 내역을 불러올 수 없습니다.")),
      );
    }

    final order = _orderDetail!;
    final f = NumberFormat('#,###');

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
            Text(
              formatDateTime(order.orderDt), // 주문 일시
              style: const TextStyle(
                fontFamily: 'Sen',
                fontSize: 14,
                color: Color(0xFF6B6E82),
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionDivider(),

            _buildMenuSummary(order),

            _buildDetailItemsBox(order, f),

            const SizedBox(height: 30),
            _buildPaymentSection(order, f),

            const SizedBox(height: 30),
            _buildSectionDivider(),

            _buildCustomerInfoSection(order),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSummary(OwnerOrderModel order) {
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
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
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
                      order.buyerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF181C2E),
                      ),
                    ),
                    Text(
                      'ID: ${order.orderId}',
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
                  order.itemSummary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181C2E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '픽업: ${formatDateTime(order.pickupDt)}',
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

  Widget _buildDetailItemsBox(OwnerOrderModel order, NumberFormat f) {
    if (order.items == null || order.items!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: order.items!.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          bool isLast = idx == order.items!.length - 1;

          return _buildItemRow(
            item.productName,
            '${item.quantity}개',
            '${f.format(item.subtotal)} 원',
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(String name, String qty, String price, {bool isLast = false}) {
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

  Widget _buildPaymentSection(OwnerOrderModel order, NumberFormat f) {
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
        _buildPriceRow('주문 금액', '${f.format(order.totalPrice)} 원'),
        _buildPriceRow('합계', '${f.format(order.totalPrice)} 원', isTotal: true),
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

  Widget _buildCustomerInfoSection(OwnerOrderModel order) {
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
        // 서버 데이터 바인딩
        _buildInfoRowWidget('주문자', order.buyerName),
        _buildInfoRowWidget('주문 상태', _getStatusText(order.orderStatus)),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'S02': return '수락됨';
      case 'S03': return '완료됨';
      case 'S04': return '취소됨';
      default: return '대기중';
    }
  }

  Widget _buildInfoRowWidget(String label, String value) {
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

  Widget _buildSectionDivider() => const Divider(height: 1, color: Color(0xFFEEF2F6));
}