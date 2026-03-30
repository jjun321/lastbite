import 'package:flutter/material.dart';
import 'shop_page.dart';

// 소비자 예약완료 페이지

class ReservationCompleteScreen extends StatelessWidget {
  const ReservationCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 중앙 (아이콘 + 텍스트)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 166.53,
                        height: 166.82,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4FA55B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 145.61,
                        height: 145.86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEAFBF0), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 74,
                          color: Color(0xFFEAFBF0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '예약 완료',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 하단 '가게화면으로' 버튼
            Positioned(
              left: 24,
              right: 24,
              top: 674,
              child: ElevatedButton(
                onPressed: () {
                  // 첫 화면으로 이동
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
                  '가게화면으로',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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