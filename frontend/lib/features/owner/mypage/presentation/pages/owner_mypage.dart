import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/owner_image_cache.dart';
import 'package:frontend/features/owner/mypage/presentation/pages/owner_accountpage.dart';
import 'package:frontend/features/owner/store/presentation/pages/owner_store_edit_page.dart';

// 사장님 마이페이지
class OwnerMyPage extends StatefulWidget {
  const OwnerMyPage({super.key});

  @override
  State<OwnerMyPage> createState() => _OwnerMyPageState();
}

class _OwnerMyPageState extends State<OwnerMyPage> {
  String _userName = '';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfileImage();
  }

  Future<void> _loadUser() async {
    final res = await AuthService.getMyProfile();
    if (res['success'] == true && mounted) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() => _userName = data['user_name'] ?? '');
    }
  }

  // 매장 등록·수정 화면에서 선택한 사진을 프로필 사진으로 동일하게 표시
  Future<void> _loadProfileImage() async {
    final cached = await OwnerImageCache.load();
    if (cached != null && mounted) {
      setState(() => _profileImage = cached);
    }
  }

  Future<void> _logout() async {
    await AuthService.clearTokens();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 백엔드 연동 후 실제 user_name을 받아옴
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
                    _userName.isEmpty ? 'User_name' : _userName,
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

            // 첫 번째 카드 (계정 관리, 로그아웃)
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF4FA75A),
                title: '계정 관리',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OwnerAccountPage(),
                    ),
                  );
                  // 계정 관리에서 돌아온 후 캐시된 프로필 사진 갱신
                  _loadProfileImage();
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              _buildMenuItem(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFE53935),
                title: '로그아웃',
                onTap: _logout,
              ),
            ]),

            const SizedBox(height: 16),

            // 두 번째 카드 (가게 정보 수정)
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.storefront_outlined,
                iconColor: const Color(0xFF4FA75A),
                title: '가게 정보 수정',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OwnerStoreEditPage(),
                    ),
                  );
                  // 가게 정보 수정에서 새 사진을 골랐으면 프로필 사진도 갱신
                  _loadProfileImage();
                },
              ),
            ]),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) => Container(
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

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) => InkWell(
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
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
