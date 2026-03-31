import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 이 파일은 앱을 처음 켰을 때 보여줄 첫 화면
/// 현재 디자인 기준으로 아래 요소를 포함
/// 1. 상단 여백
/// 2. 가운데 로고 이미지
/// 3. 하단 안내 문구
/// 4. "시작하기" 버튼

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 전체 배경색
      /// 이미지처럼 아주 연한 회색톤 배경을 사용
      backgroundColor: const Color(0xFFF3F3F3),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),

          child: Column(
            children: [
              /// 위쪽 여백
              /// 화면 상단 상태바와의 간격을 넉넉하게 주기 위해 사용
              const SizedBox(height: 80),

              /// 남은 공간을 위쪽과 아래쪽으로 나누기 위해 Expanded 사용
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 로고 이미지
                    Image.asset(
                      'assets/images/logo_lastbite.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              /// 하단 안내 문구
              GestureDetector(
                onTap: () {
                  context.go('/login');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '사장님이신가요? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A8A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '사장님으로 시작하기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    /// 버튼 클릭 시 로그인 화면으로 이동
                    /// go_router를 사용하므로 context.go('/login') 사용
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA75A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
