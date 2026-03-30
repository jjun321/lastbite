import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import 'owner_order_detail_screen.dart';

// 점주 주문 접수/ 주문 내역 페이지

class OwnerOrderManagementScreen extends StatefulWidget {
  final bool initialHistoryMode;
  const OwnerOrderManagementScreen({Key? key, this.initialHistoryMode = false}) : super(key: key);

  @override
  State<OwnerOrderManagementScreen> createState() => _OwnerOrderManagementScreenState();
}

class _OwnerOrderManagementScreenState extends State<OwnerOrderManagementScreen> {
  late bool isHistoryMode;

  @override
  void initState() {
    super.initState();
    isHistoryMode = widget.initialHistoryMode;
  }

  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required Color actionColor,
    required Order order,
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
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF676C5A),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (toAccepted) {
                            order.isAccepted = true;
                            order.isCancelled = false;
                          } else {
                            order.isAccepted = false;
                            order.isCancelled = true;
                          }
                          isHistoryMode = true;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '예',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: const Color(0xFFB3BA9F)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '아니오',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFB3BA9F)),
                        ),
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
    final List<Order> displayList = isHistoryMode
        ? orderList.where((o) => o.isAccepted || o.isCancelled).toList()
        : orderList.where((o) => !o.isAccepted && !o.isCancelled).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
            child: displayList.isEmpty
                ? const Center(child: Text('주문이 없습니다.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(displayList[index]);
              },
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
          Expanded(child: _buildTabItem("들어온 주문", !isHistoryMode, () => setState(() => isHistoryMode = false))),
          const SizedBox(width: 16),
          Expanded(child: _buildTabItem("주문 내역", isHistoryMode, () => setState(() => isHistoryMode = true))),
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
        child: Text(label,
            style: TextStyle(
                color: isActive ? const Color(0xFF4FA55B) : const Color(0xFF1E1E1E),
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerOrderDetailScreen(order: order),
          ),
        ).then((_) {
          setState(() {}); // 상세에서 돌아오면 상태 반영
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(top: BorderSide(color: Color(0xFFEEF2F6))),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.representativeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF181C2E))),
                            const SizedBox(height: 2),
                            Text('${order.totalCountString} | ${order.price}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF181C2E))),
                            const SizedBox(height: 4),
                            Text('픽업: ${order.pickupTime}',
                                style: const TextStyle(
                                    color: Color(0xFF6B6E82), fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(order.orderNo,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B6E82),
                                  decoration: TextDecoration.underline)),
                          const SizedBox(height: 4),
                          if (order.isCancelled)
                            const Text('취소됨',
                                style: TextStyle(
                                    color: Color(0xFFD63030),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))
                          else if (order.isAccepted)
                            const Text('수락됨',
                                style: TextStyle(
                                    color: Color(0xFF4FA55B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildActionButton(
                    order.isAccepted && !order.isCancelled ? '수락됨' : '주문 수락',
                    order.isAccepted && !order.isCancelled
                        ? const Color(0xFFB3BA9F)
                        : const Color(0xFF4FA55B), () {
                  if (order.isAccepted && !order.isCancelled) return;
                  _showConfirmDialog(
                    context: context,
                    title: '이 주문을 수락하시겠습니까?',
                    actionColor: const Color(0xFF4FA55B),
                    order: order,
                    toAccepted: true,
                  );
                }),
                const SizedBox(width: 12),
                _buildActionButton(
                    order.isCancelled ? '취소됨' : '주문 취소',
                    order.isCancelled
                        ? const Color(0xFFB3BA9F)
                        : const Color(0xFFD63030), () {
                  if (order.isCancelled) return;
                  _showConfirmDialog(
                    context: context,
                    title: '이 주문을 취소하시겠습니까?',
                    actionColor: const Color(0xFFD63030),
                    order: order,
                    toAccepted: false,
                  );
                }),
              ],
            ),
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
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ),
    );
  }
}