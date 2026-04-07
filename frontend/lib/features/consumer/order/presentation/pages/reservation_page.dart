import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';

import 'complete_page.dart';

class ReservationScreen extends StatefulWidget {
  final CartModel cart; // cart_page에서 넘겨받음

  const ReservationScreen({Key? key, required this.cart}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _repo = OrderRepositoryImpl();
  bool _isLoading = false;
  DateTime _pickupDt = DateTime.now().add(const Duration(hours: 1));

  Future<void> _createOrder() async {
    setState(() => _isLoading = true);
    try {

      await _repo.createOrder(
        storeId: widget.cart.storeId,
        // ✅ 해결 시도 1: DateTime을 String(ISO8601)으로 변환해서 전달
        // 만약 repo의 createOrder가 DateTime을 받는다면,
        // 해당 repo 안에서 .toIso8601String() 처리가 되어있는지 확인해야 합니다.
        pickupDt: _pickupDt,
        items: widget.cart.items
            .map((e) => OrderItemModel(
          productId: e.productId,
          productName: e.productName,
          quantity: e.quantity,
          productDisPrice: e.productDisPrice,
          productOriPrice: e.productDisPrice,
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
    } catch (e, stackTrace) {  // stackTrace 추가
      print('❌ 에러 발생: $e');
      print('❌ 위치: $stackTrace'); // 어느 파일 몇 번째 줄인지 알려줍니다.
      // ✅ 해결 시도 2: 에러 상세 분석 (서버가 보내주는 진짜 에러 메시지 확인)
      String errorMessage = '주문 생성에 실패했습니다.';


      if (e is DioException) {
        // 서버 응답 본문에 에러 이유가 적혀있을 경우 (예: {"message": "상품 재고 부족"})
        final serverMessage = e.response?.data;
        print('❌ 서버 상세 에러: $serverMessage');
        errorMessage = '서버 오류 (500): ${serverMessage ?? "서버 내부 로직 에러"}';
      } else {
        print('❌ 기타 에러: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

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
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF0F4), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Color(0xFF181C2E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('예약하기',
                      style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
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

                    // 가게 요약
                    Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF98A8B8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cart.storeName,
                                      style: const TextStyle(
                                          fontFamily: 'Sen', fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  const Text('주문번호 #대기중',
                                      style: TextStyle(fontSize: 14,
                                          color: Color(0xFF6B6E82),
                                          decoration: TextDecoration.underline)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('${cart.totalQuantity}개',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.bold)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('|', style: TextStyle(color: Color(0xFFCACCDA))),
                                  ),
                                  Text('${cart.totalPrice}원',
                                      style: const TextStyle(
                                          fontSize: 14, color: Color(0xFF6B6E82))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '픽업 ${_pickupDt.toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B6E82)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFEEF2F6), thickness: 1),
                    ),

                    // 주문 메뉴 목록
                    const Text('주문 메뉴',
                        style: TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: cart.items.map((item) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.productName} | ${item.quantity}개',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF181C2E))),
                                  Text('${item.subtotal}원',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF828282))),
                                ],
                              ),
                            ),
                        ).toList(),
                      ),
                    ),

                    // 결제 금액
                    const SizedBox(height: 30),
                    const Text('결제 금액',
                        style: TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildRow('합계', '${cart.totalPrice}원', isBold: true),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 예약하기 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('예약하기',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF717171))),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}