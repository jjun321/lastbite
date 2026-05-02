import 'package:flutter/material.dart';
import 'package:frontend/features/owner/order_manage/data/models/owner_order_model.dart';
import 'package:frontend/services/order_service.dart';
import 'owner_order_detail_page.dart';

class OwnerOrderManagementScreen extends StatefulWidget {
  final bool initialHistoryMode;
  const OwnerOrderManagementScreen({Key? key, this.initialHistoryMode = false}) : super(key: key);

  @override
  State<OwnerOrderManagementScreen> createState() => _OwnerOrderManagementScreenState();
}

class _OwnerOrderManagementScreenState extends State<OwnerOrderManagementScreen> {
  late bool isHistoryMode;
  final OrderService _orderService = OrderService();
  List<OwnerOrderModel> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isHistoryMode = widget.initialHistoryMode;
    _fetchData();
  }

  // ISO8601 시간을 보기 좋게 변환하는 헬퍼 함수
  String formatPickupTime(String timeStr) {
    try {
      DateTime dt = DateTime.parse(timeStr);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      List<OwnerOrderModel> result = isHistoryMode
          ? await _orderService.fetchHistory()
          : await _orderService.fetchOrders();
      setState(() => _orders = result);
    } catch (e) {
      debugPrint("데이터 로딩 오류: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required Color actionColor,
    required OwnerOrderModel order,
    required bool toAccepted,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F3E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 323,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        bool success = toAccepted
                            ? await _orderService.acceptOrder(order.orderId)
                            : await _orderService.cancelOrder(order.orderId);
                        if (success) _fetchData();
                      },
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(color: actionColor, borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.center,
                        child: const Text('예', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB3BA9F)), borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.center,
                        child: const Text('아니오', style: TextStyle(color: Color(0xFFB3BA9F))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          isHistoryMode ? '주문 내역' : '주문 접수',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          _buildTabButtons(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FA55B)))
                : RefreshIndicator(
              onRefresh: _fetchData,
              child: _orders.isEmpty
                  ? const Center(child: Text('주문 내역이 없습니다.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _orders.length,
                itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
      child: Row(
        children: [
          Expanded(child: _buildTabItem("들어온 주문", !isHistoryMode, () {
            if (isHistoryMode) {
              setState(() => isHistoryMode = false);
              _fetchData();
            }
          })),
          const SizedBox(width: 16),
          Expanded(child: _buildTabItem("주문 내역", isHistoryMode, () {
            if (!isHistoryMode) {
              setState(() => isHistoryMode = true);
              _fetchData();
            }
          })),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAFBF0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF4FA55B) : const Color(0xFFE4E4E4)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isActive ? const Color(0xFF4FA55B) : const Color(0xFF1E1E1E), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildOrderCard(OwnerOrderModel order) {
    String statusText = '';
    Color statusColor = const Color(0xFF6B6E82);

    switch (order.orderStatus) {
      case 'S02': statusText = '수락됨'; statusColor = const Color(0xFF4FA55B); break;
      case 'S03': statusText = '완료됨'; statusColor = const Color(0xFF4FA55B); break;
      case 'S04': statusText = '취소됨'; statusColor = const Color(0xFFFF0000); break;
      default: statusText = '대기중'; statusColor = const Color(0xFF6B6E82);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OwnerOrderDetailScreen(orderId: order.orderId)),
      ).then((_) => _fetchData()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEF2F6)))),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: const Color(0xFF98A8B8), borderRadius: BorderRadius.circular(8)),
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
                          Text(order.buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Text('${order.itemSummary} | ${order.totalPrice}원', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      // 시간 포맷 적용 부분
                      Text('픽업: ${formatPickupTime(order.pickupDt)}', style: const TextStyle(color: Color(0xFF6B6E82), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (order.orderStatus != 'S03') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildActionButton('주문 수락', order.orderStatus == 'S02' ? const Color(0xFFB3BA9F) : const Color(0xFF4FA55B), () => _showConfirmDialog(context: context, title: '주문을 수락하시겠습니까?', actionColor: const Color(0xFF4FA55B), order: order, toAccepted: true)),
                  const SizedBox(width: 12),
                  _buildActionButton('주문 취소', order.orderStatus == 'S04' ? const Color(0xFFB3BA9F) : const Color(0xFFD63030), () => _showConfirmDialog(context: context, title: '주문을 취소하시겠습니까?', actionColor: const Color(0xFFD63030), order: order, toAccepted: false)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}