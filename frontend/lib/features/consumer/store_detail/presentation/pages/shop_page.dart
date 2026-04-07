import 'package:flutter/material.dart';
import 'package:frontend/data/mock_data.dart'; // 데이터 파일 임포트
import 'package:frontend/features/consumer/order/presentation/pages/order_page.dart';

//(소비자) 가게 화면 페이지

class ShopPage extends StatelessWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 바 (뒤로가기 + 가게 이름)
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
                  Text(
                    myStore.name,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF181C2E),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 223,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4C4C4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 20),
                      child: Text(
                        myStore.name,
                        style: const TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF181C2E),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        myStore.description,
                        style: const TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          color: Color(0xFF32343E),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: Color(0xFFA0A5BA), thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 주소 텍스트
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: '주소 ',
                                  style: TextStyle(
                                    fontFamily: 'Sen',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF181C2E),
                                  ),
                                ),
                                TextSpan(
                                  text: myStore.address,
                                  style: const TextStyle(
                                    fontFamily: 'Sen',
                                    fontSize: 14,
                                    color: Color(0xFF32343E),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                // 지도 연결 로직 자리
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E3E5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '네이버지도',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF32343E),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.north_east,
                                      size: 14,
                                      color: Color(0xFF32343E),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 188,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF11A94D),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          color: Color(0xFF11A94D),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // 3. 하단 고정 주문하기 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '주문하기',
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
}
