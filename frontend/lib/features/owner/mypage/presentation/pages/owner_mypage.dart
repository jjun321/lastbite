import 'package:flutter/material.dart';

class OwnerMyPage extends StatelessWidget {
  const OwnerMyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 프로필 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    '이름칸',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // 첫 번째 카드 (계정 관리, 로그아웃)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_profile.png',
                title: '계정 관리',
                onTap: () {},
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              _buildMenuItem(
                iconPath: 'assets/images/icon_logout.png',
                title: '로그아웃',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 16),

            // 두 번째 카드 (가게 정보)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_mypage.png', // 가게 정보 아이콘으로 사용
                title: '가게 정보',
                onTap: () {},
              ),
            ]),

            const Spacer(),

            // 하단 네비게이션 바 (Mockup for Owner)
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildNavItem('assets/images/icon_home.png', '홈', false),
                   _buildNavItem('assets/images/icon_board.png', '판매설정', false), // 아이콘 변경 가능
                   _buildNavItem('assets/images/icon_noti.png', '주문알림', false),
                   _buildNavItem('assets/images/icon_mypage.png', '마이페이지', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F1F1)),
              ),
              child: Image.asset(iconPath),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, bool isActive) {
    final color = isActive ? const Color(0xFF6DA06D) : const Color(0xFF999999);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          iconPath,
          width: 24,
          height: 24,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
