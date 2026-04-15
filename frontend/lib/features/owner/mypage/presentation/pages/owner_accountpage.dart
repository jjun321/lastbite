import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

// 사장님 계정 관리 페이지 — 백엔드 연동
// 프로필 사진 수정, 아이디/이메일/연락처 확인 및 수정 기능
class OwnerAccountPage extends StatefulWidget {
  const OwnerAccountPage({super.key});

  @override
  State<OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends State<OwnerAccountPage> {
  // 백엔드 연동 후 실제 사용자 정보를 불러오기
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await AuthService.getMyProfile();
    if (res['success'] == true && mounted) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['user_name'] ?? '';
        _emailController.text = data['user_email'] ?? '';
        _phoneController.text = data['user_phone'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final res = await AuthService.updateMyProfile(
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
      );
      if (res['success'] == true) {
        _showSnack('저장되었습니다.');
      } else {
        _showSnack(res['message'] ?? '저장에 실패했습니다.');
      }
    } catch (e) {
      _showSnack('오류: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 (뒤로가기 + 타이틀)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '계정 관리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            // 본문 영역 — 로딩 여부와 무관하게 항상 텍스트 필드 렌더링
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 프로필 아바타 + 편집 아이콘
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // TODO: 프로필 사진 변경 (POST /users/me/profile-image)
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── 아이디 필드 ──
                    _buildLabel('아이디'),
                    const SizedBox(height: 8),
                    _buildTextField(_nameController, hint: 'user_name'),

                    const SizedBox(height: 24),

                    // ── 이메일 필드 ──
                    _buildLabel('이메일'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _emailController,
                      hint: 'user@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 24),

                    // 연락처 필드
                    _buildLabel('연락처'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _phoneController,
                      hint: '010-0000-0000',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 40),

                    // 데이터 로딩 중 표시
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4FA75A),
                          ),
                        ),
                      ),

                    // 저장하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isLoading)
                            ? null
                            : _save, // 백엔드 저장 API 연동
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FA75A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '저장하기',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl, {
    String hint = '',
    TextInputType? keyboardType,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4CAF50)),
      ),
    ),
    style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
  );
}
