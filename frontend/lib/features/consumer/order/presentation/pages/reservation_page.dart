import 'package:flutter/material.dart';
import 'package:frontend/data/mock_data.dart';
import 'package:frontend/data/models.dart';
import 'complete_page.dart';

// 예약하기 페이지

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. 픽업 시간 계산 로직
    String getPickupTime() {
      DateTime now = DateTime.now();
      String dateStr =
          "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}";
      int hour = int.parse(myStore.closingTime.split(":")[0]);
      int min = int.parse(myStore.closingTime.split(":")[1]);
      String startTime =
          "${(min < 30 ? hour - 1 : hour)}:${(min < 30 ? min + 30 : min - 30).toString().padLeft(2, '0')}";
      String endTime = myStore.closingTime;
      return "$dateStr. $startTime~$endTime PM";
    }

    // 2. 금액 및 수량 계산
    int totalQuantity = myCart.fold(0, (sum, item) => sum + item.quantity);
    int totalOriginalPrice = myCart.fold(
      0,
      (sum, item) => sum + (item.menu.originalPrice * item.quantity),
    );
    int totalPrice = myCart.fold(0, (sum, item) => sum + item.totalPrice);
    int totalDiscount = totalOriginalPrice - totalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- 상단 바 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF0F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF181C2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '예약하기',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 17,
                      color: Color(0xFF181C2E),
                    ),
                  ),
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
                    // --- 가게 요약 정보 ---
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    myStore.name,
                                    style: const TextStyle(
                                      fontFamily: 'Sen',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    '주문번호 #대기중',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B6E82),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '$totalQuantity개',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF181C2E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '|',
                                      style: TextStyle(
                                        color: Color(0xFFCACCDA),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$totalPrice원',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B6E82),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '픽업 ${getPickupTime()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B6E82),
                                ),
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

                    // --- 주문 메뉴 목록 ---
                    const Text(
                      '주문 메뉴',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: myCart
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${item.menu.name} | ${item.quantity}개",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF181C2E),
                                      ),
                                    ),
                                    Text(
                                      '${item.totalPrice}원',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF828282),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    // --- 결제 금액 ---
                    const SizedBox(height: 30),
                    const Text(
                      '결제 금액',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRow('정가', '$totalOriginalPrice원'),
                    _buildRow('할인액', '-$totalDiscount원'),
                    _buildRow(
                      '합계',
                      '$totalPrice원',
                      isBold: true,
                      valueColor: Colors.black,
                    ),

                    // --- 주문자 정보 ---
                    const SizedBox(height: 30),
                    const Divider(color: Color(0xFFEEF2F6)),
                    const SizedBox(height: 10),
                    const Text(
                      '주문자 정보',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRow('주문자', currentUser.name),
                    _buildRow('연락처', currentUser.phoneNumber),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // --- 하단 버튼 ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  if (myCart.isEmpty) return;

                  final newOrder = Order(
                    orderNo:
                        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    items: List.from(myCart), // 장바구니 리스트
                    price: "$totalPrice 원",
                    pickupTime: getPickupTime(),
                    isAccepted: false,
                    isCancelled: false,
                  );

                  orderList.insert(0, newOrder);

                  myCart.clear();

                  // 완료 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReservationCompleteScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '예약하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color labelColor = const Color(0xFF717171),
    Color valueColor = const Color(0xFF1E1E1E),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
