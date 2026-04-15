import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/features/consumer/mypage/presentation/pages/consumer_accountpage.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/consumer/mypage/presentation/pages/favorite_page.dart';
import 'package:go_router/go_router.dart';

class ConsumerMyPage extends StatefulWidget {
  const ConsumerMyPage({super.key});

  @override
  State<ConsumerMyPage> createState() => _ConsumerMyPageState();
}

class _ConsumerMyPageState extends State<ConsumerMyPage> {
  final _authRepo = AuthRepositoryImpl();
  String _userName = 'User_name';
  File? _profileImage;

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
      });
    }
  }

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
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // 첫 번째 카드 (계정 관리, 즐겨찾기)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_profile.png',
                title: '계정 관리',
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ConsumerAccountPage(),
                    ),
                  );
                  // 프로필 이미지가 수정되었을 경우 수정하여 반영
                  if (result != null && result is File) {
                    setState(() {
                      _profileImage = result;
                    });
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              _buildMenuItem(
                iconPath: 'assets/images/icon_favorites.png',
                title: '즐겨찾기',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritePage()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 16),

            // 두 번째 카드 (알림 설정)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_noti.png',
                title: '알림 설정',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 16),

            // 세 번째 카드 (로그아웃)
            _buildMenuCard([
              _buildMenuItem(
                iconPath: 'assets/images/icon_logout.png',
                title: '로그아웃',
                onTap: () async {
                  await _authRepo.logout();
                  if (mounted) {
                    context.go('/login');
                  }
                },
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
