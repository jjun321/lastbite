import 'package:flutter/material.dart';
import 'package:frontend/features/owner/mypage/presentation/pages/owner_accountpage.dart';

class OwnerMyPage extends StatelessWidget {
  const OwnerMyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 백엔드 연동 후 실제 user_name을 받아오도록 수정
    const String userName = 'User_name';

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
                  CircleAvatar(radius: 50, backgroundColor: Colors.grey[300]),
                  const SizedBox(width: 20),
                  const Text(
                    userName,
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OwnerAccountPage()),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              _buildMenuItem(
                iconPath: 'assets/images/icon_logout.png',
                title: '로그아웃',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 16),

            // 두 번째 카드 (가게 정보 수정)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_mypage.png',
                title: '가게 정보 수정',
                onTap: () {},
              ),
            ]),

            const Spacer(),
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
            color: Colors.black.withValues(alpha: 0.03),
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
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
