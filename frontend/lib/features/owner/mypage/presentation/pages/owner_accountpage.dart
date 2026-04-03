import 'package:flutter/material.dart';

/// 사장님 계정 관리 페이지
/// 프로필 사진 수정, 아이디/이메일/연락처 확인 및 수정 기능
class OwnerAccountPage extends StatefulWidget {
  const OwnerAccountPage({super.key});

  @override
  State<OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends State<OwnerAccountPage> {
  // TODO: 백엔드 연동 후 실제 사용자 정보를 불러오도록 수정
  final _nameController = TextEditingController(text: 'user_name');
  final _emailController =
      TextEditingController(text: 'user_email(00000@hansung.ac.kr)');
  final _phoneController = TextEditingController(text: 'user_phone');

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
            // ── 상단 헤더 (뒤로가기 + 타이틀) ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/icon_back.png',
                          width: 24,
                          height: 24,
                          color: const Color(0xFF333333),
                        ),
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

            // ── 본문 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── 프로필 아바타 + 편집 아이콘 ──
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
                                // TODO: 프로필 사진 변경 기능 구현
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'assets/images/icon_edit.png',
                                    color: Colors.white,
                                  ),
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
                    _buildTextField(_nameController),

                    const SizedBox(height: 24),

                    // ── 이메일 필드 ──
                    _buildLabel('이메일'),
                    const SizedBox(height: 8),
                    _buildTextField(_emailController),

                    const SizedBox(height: 24),

                    // ── 연락처 필드 ──
                    _buildLabel('연락처'),
                    const SizedBox(height: 8),
                    _buildTextField(_phoneController),

                    const SizedBox(height: 40),

                    // ── 저장하기 버튼 ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 백엔드 저장 API 연동
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF666666),
      ),
    );
  }
}
