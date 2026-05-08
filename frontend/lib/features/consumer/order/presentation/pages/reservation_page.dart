import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'complete_page.dart'; // 여기에 ReservationCompleteScreen이 있다고 가정합니다.

class ReservationScreen extends StatefulWidget {
  final CartModel cart;
  const ReservationScreen({Key? key, required this.cart}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _repo = OrderRepositoryImpl();
  final _authRepo = AuthRepositoryImpl();
  bool _isLoading = false;
  final DateTime _pickupDt = DateTime.now().add(const Duration(hours: 1));
  String _userName = '로드 중...';
  String _userPhone = '010-0000-0000';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authRepo.getUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user.userName;
        _userPhone = user.userPhone;
      });
    }
  }

  // 주문 생성 로직
  Future<void> _createOrder() async {
    setState(() => _isLoading = true);
    try {
      await _repo.createOrder(
        storeId: widget.cart.storeId,
        pickupDt: _pickupDt,
        items: widget.cart.items
            .map((e) => OrderItemModel(
          productId: e.productId,
          productName: e.productName,
          quantity: e.quantity,
          productDisPrice: e.productDisPrice,
          productOriPrice: e.productOriPrice,
          subtotal: e.subtotal,
        ))
            .toList(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReservationCompleteScreen()),
        );
      }
    } catch (e) {
      String errorMessage = '주문 생성에 실패했습니다.';
      if (e is DioException) {
        final serverMessage = e.response?.data;
        errorMessage = '서버 오류: ${serverMessage ?? "잠시 후 다시 시도해주세요."}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    final String displayMenuName = cart.items.length > 1 ? '${cart.items[0].productName}외' : cart.items[0].productName;

    final int totalOriPrice = cart.items.fold<int>(0, (sum, item) => sum + (item.productOriPrice * item.quantity));
    final int totalDiscount = totalOriPrice - cart.totalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // 가게 이름 디자인
                    Text(cart.storeName, style: const TextStyle(fontFamily: 'Sen', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 8),
                    // 메뉴외 | 총개수 | 합계 디자인 유지
                    Row(
                      children: [
                        Text(displayMenuName, style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: Color(0xFFCACCDA)))),
                        Text('총 ${cart.totalQuantity}개', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: Color(0xFFCACCDA)))),
                        Text('${cart.totalPrice}원', style: const TextStyle(fontFamily: 'Sen', fontSize: 14, color: Color(0xFF6B6E82))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '픽업 ${_pickupDt.toString().substring(0, 16).replaceAll('T', ' ')}',
                      style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFEEF2F6), thickness: 1)),

                    const Text('주문 메뉴', style: TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildMenuBox(cart),

                    const SizedBox(height: 30),
                    const Text('결제 금액', style: TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 12),
                    _row('정가', '${totalOriPrice}원'),
                    _row('할인액', totalDiscount > 0 ? '-${totalDiscount}원' : '0원', valueColor: totalDiscount > 0 ? Colors.red : null),
                    _row('합계', '${cart.totalPrice}원', isBold: true),

                    const SizedBox(height: 30),
                    const Text('주문자 정보', style: TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 12),
                    _row('주문자', _userName, isBold: true),
                    _row('연락처', _userPhone, isBold: true),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildOrderButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 45, height: 45, decoration: const BoxDecoration(color: Color(0xFFECF0F4), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF181C2E)))),
      const SizedBox(width: 16),
      const Text('예약 확인', style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
    ]),
  );

  Widget _buildMenuBox(CartModel cart) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
    child: Column(children: cart.items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${i.productName} | ${i.quantity}개', style: const TextStyle(fontFamily: 'Sen')), Text('${i.subtotal}원', style: const TextStyle(fontFamily: 'Sen'))]))).toList()),
  );

  Widget _row(String label, String value, {bool isBold = false, Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontFamily: 'Sen', color: Color(0xFF6B6E82))),
        Text(value, style: TextStyle(fontFamily: 'Sen', fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? const Color(0xFF181C2E)))
      ]));

  Widget _buildOrderButton() => Padding(
    padding: const EdgeInsets.all(24),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _createOrder,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4FA55B), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      child: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('예약하기', style: TextStyle(fontFamily: 'Sen', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}