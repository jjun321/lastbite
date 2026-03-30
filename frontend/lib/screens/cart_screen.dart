import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import 'reservation_screen.dart';

// 소비자 장바구니 페이지

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int get totalQuantity => myCart.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice => myCart.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 상단 헤더
            Positioned(
              top: 34, left: 24, right: 24,
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
                  const Text('장바구니', style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
                ],
              ),
            ),

            // 2. 장바구니 리스트
            Positioned(
              top: 100, left: 21, right: 21, bottom: 200,
              child: myCart.isEmpty
                  ? const Center(child: Text("장바구니가 비어있습니다."))
                  : ListView.builder(
                itemCount: myCart.length,
                itemBuilder: (context, index) => _buildCartItem(myCart[index]),
              ),
            ),

            // 3. 하단 요약 영역
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 총 수량 및 가격 요약 바
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '총 수량 ',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF181C2E)),
                              children: [
                                TextSpan(
                                  text: '$totalQuantity',
                                  style: const TextStyle(color: Color(0xFF4FA55B), fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: '개'),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Text('총 금액', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 20),
                              Text('$totalPrice원', style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 예약하기 버튼
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReservationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FA55B),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                          '예약하기',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 개별 아이템 디자인
  Widget _buildCartItem(CartItem cartItem) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.menu.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (cartItem.quantity > 1) cartItem.quantity--;
                        else myCart.remove(cartItem);
                      }),
                      child: const Icon(Icons.remove_circle_outline, size: 22),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => cartItem.quantity++),
                      child: const Icon(Icons.add_circle_outline, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => setState(() => myCart.remove(cartItem)),
                child: const Icon(Icons.cancel_outlined, size: 20, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text('${cartItem.totalPrice}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}