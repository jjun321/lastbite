import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';

import 'complete_page.dart';

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
  DateTime _pickupDt = DateTime.now().add(const Duration(hours: 1));

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
        )).toList(),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    // 결제 금액 계산
    final int totalOriPrice = cart.items.fold<int>(0, (sum, item) {
      return sum + (item.productOriPrice * item.quantity);
    });
    final int totalDiscount = totalOriPrice - cart.totalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45, height: 45,
                      decoration: const BoxDecoration(color: Color(0xFFECF0F4), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF181C2E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('예약하기', style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // 가게 이름
                    Text(cart.storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFEEF2F6), thickness: 1),
                    ),

                    // 주문 메뉴 섹션
                    const Text('주문 메뉴', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: cart.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.productName} | ${item.quantity}개', style: const TextStyle(color: Color(0xFF181C2E))),
                              Text('${item.subtotal}원', style: const TextStyle(color: Color(0xFF181C2E))),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ 결제 금액 섹션
                    const Text('결제 금액', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 12),
                    _buildRow('정가', '${totalOriPrice}원'),
                    _buildRow('할인액', '-${totalDiscount}원', valueColor: Colors.red),
                    _buildRow('합계', '${cart.totalPrice}원', isBold: true),

                    const SizedBox(height: 30),

                    // ✅ 주문자 정보 섹션 (배경색 제거 및 양 끝 정렬)
                    const Text('주문자 정보', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF181C2E))),
                    const SizedBox(height: 12),
                    // Container의 배경색과 패딩을 제거하고 직접 Row들을 배치
                    _buildRow('주문자', _userName, isBold: true),
                    _buildRow('연락처', _userPhone, isBold: true),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 예약 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('예약하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 결제 금액과 주문자 정보 모두에 공통으로 사용되는 Row 빌더
  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝으로 정렬
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B6E82), fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF181C2E),
            ),
          ),
        ],
      ),
    );
  }
}