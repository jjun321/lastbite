import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/owner/order_manage/data/models/owner_order_model.dart';
import 'package:frontend/services/order_service.dart';

class OwnerOrderDetailScreen extends StatefulWidget {
  final OwnerOrderModel order;

  const OwnerOrderDetailScreen({super.key, required this.order});

  @override
  State<OwnerOrderDetailScreen> createState() => _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends State<OwnerOrderDetailScreen> {
  final OrderService _orderService = OrderService();
  late OwnerOrderModel _currentOrder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    setState(() => _isLoading = true);
    try {
      final detailOrder = await _orderService.fetchOrderDetail(widget.order.orderId);
      if (mounted) {
        if (detailOrder != null) {
          setState(() {
            _currentOrder = detailOrder;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatPrice(int price) =>
      NumberFormat('###,###,###').format(price);

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "-";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy.MM.dd HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isLoading && _currentOrder.items == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FA55B)))
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '주문번호 #${_currentOrder.orderId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF181C2E)),
                          ),
                          Text(
                            _formatDate(_currentOrder.orderDt),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B6E82)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStoreSummary(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('주문 메뉴'),
                    const SizedBox(height: 12),
                    _buildMenuDetailSection(),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPaymentSection(),
                    ),
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 1, color: Color(0xFFEEF2F6)),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('주문자 정보'),
                    _buildUserInfoSection(),
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
              decoration: const BoxDecoration(color: Color(0xFFECF0F4), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF181C2E)),
            ),
          ),
          const SizedBox(width: 16),
          const Text('주문 상세', style: TextStyle(fontSize: 17, color: Color(0xFF181C2E), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStoreSummary() {
    final items = _currentOrder.items ?? [];
    final totalCount = items.fold(0, (sum, i) => sum + i.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storefront, color: Color(0xFF6B6E82)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("주문 요약", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('총 $totalCount개', style: const TextStyle(fontSize: 14, color: Color(0xFF181C2E))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: Color(0xFFCACCDA)))),
                        Text('${_formatPrice(_currentOrder.totalPrice)}원', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('픽업 예정: ${_formatDate(_currentOrder.pickupDt)}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B6E82))),
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

  // 메뉴 상세 섹션 수정 (오버플로우 방지)
  Widget _buildMenuDetailSection() {
    final items = _currentOrder.items;

    if (items == null || items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(child: Text("메뉴 상세 내역을 불러오는 중입니다.")),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0))),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    // 1. 메뉴명과 개수를 묶어서 Expanded로 감싸 왼쪽 영역을 차지하게 함
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181C2E)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.quantity}개',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B6E82)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. 가격은 Expanded 밖에 두어 오른쪽 끝에 정렬됨
                    Text(
                      '${_formatPrice(item.subtotal)}원',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181C2E)),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('결제 금액', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF181C2E))),
        const SizedBox(height: 16),
        _buildPriceRow('정가', '${_formatPrice(_currentOrder.totalOriPrice)}원'),
        const SizedBox(height: 8),
        _buildPriceRow('할인액', '- ${_formatPrice(_currentOrder.totalDiscount)}원', isDiscount: true),
        const SizedBox(height: 16),
        _buildPriceRow('합계', '${_formatPrice(_currentOrder.totalPrice)}원', isTotal: true),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    final String name = _currentOrder.buyer?['user_name'] ?? _currentOrder.buyerName;
    final String phone = _currentOrder.buyer?['user_phone'] ?? "연락처 미등록";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _buildInfoRow('주문자', name, isBold: true),
          const SizedBox(height: 8),
          _buildInfoRow('연락처', phone, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF181C2E)),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6B6E82))),
        Text(price,
            style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isDiscount ? Colors.red : const Color(0xFF181C2E))),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B6E82), fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF181C2E))),
      ],
    );
  }
}