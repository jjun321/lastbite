import 'package:flutter/material.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final bool isCancelled;

  const OrderDetailScreen({
    Key? key,
    required this.order,
    this.isCancelled = false,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderRepo = OrderRepositoryImpl();
  final _authRepo = AuthRepositoryImpl();

  late OrderModel _currentOrder;
  String _userName = '로드 중...';
  String _userPhone = '-';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _loadFullData();
  }

  Future<void> _loadFullData() async {
    setState(() => _isLoading = true);
    try {
      final fullOrder = await _orderRepo.getOrderDetail(widget.order.orderId);
      final user = await _authRepo.getUser();

      if (mounted) {
        setState(() {
          _currentOrder = fullOrder;
          if (user != null) {
            _userName = user.userName;
            _userPhone = user.userPhone;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터를 불러오는 데 실패했습니다.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FA55B)))
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isCancelled) _buildOrderNumberCard('#${_currentOrder.orderId}'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _currentOrder.orderDt.toString().substring(0, 16),
                        style: const TextStyle(fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82)),
                      ),
                    ),
                    const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF181C2E),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _buildRow('주문자', _userName, isBold: true),
          _buildRow('연락처', _userPhone, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B6E82), fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
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
          const Text('주문 상세', style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
        ],
      ),
    );
  }

  Widget _buildOrderNumberCard(String orderNo) {
    return Center(
      child: Container(
        width: 342, height: 159,
        decoration: BoxDecoration(color: const Color(0xFF4FA55B), borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('주문번호', style: TextStyle(fontFamily: 'Sen', fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            Text(orderNo, style: const TextStyle(fontFamily: 'Sen', fontSize: 36, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSummary() {
    final totalCount = _currentOrder.items.fold(0, (sum, i) => sum + i.quantity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: const Color(0xFF98A8B8), borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currentOrder.storeName, style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('#${_currentOrder.orderId}', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82), decoration: TextDecoration.underline)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('총 $totalCount개', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: Color(0xFFCACCDA)))),
                        Text('${_formatPrice(_currentOrder.totalPrice)}원', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('픽업 ${_currentOrder.pickupDt.toString().substring(0, 16)}', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82))),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: _currentOrder.items.map((item) {
          final isLast = item == _currentOrder.items.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // 1. 메뉴명과 개수 영역 (왼쪽 정렬)
                    Expanded( // 이 Expanded가 오른쪽 가격을 끝으로 밀어주는 역할을 합니다.
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF181C2E)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8), // 메뉴명과 개수 사이 최소 간격
                          Text(
                            '${item.quantity}개',
                            style: const TextStyle(
                                fontFamily: 'Sen',
                                fontSize: 12,
                                color: Color(0xFF6B6E82)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. 가격 영역 (오른쪽 정렬)
                    Text(
                      '${_formatPrice(item.subtotal)}원',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF828282)),
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

  Widget _buildPaymentSection() {
    final int originalTotal = _currentOrder.items.fold(0, (sum, i) => sum + (i.productOriPrice * i.quantity));
    final int discount = originalTotal - _currentOrder.totalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('결제 금액', style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF181C2E))),
        const SizedBox(height: 16),
        _buildPriceRow('정가', '${_formatPrice(originalTotal)}원'),
        const SizedBox(height: 8),
        _buildPriceRow('할인액', '- ${_formatPrice(discount)}원', isDiscount: true),
        const SizedBox(height: 12),
        _buildPriceRow('합계', '${_formatPrice(_currentOrder.totalPrice)}원', isTotal: true),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFEEF2F6)),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF717171))),
        Text(price,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : (isDiscount ? Colors.red : const Color(0xFF828282)))),
      ],
    );
  }
}