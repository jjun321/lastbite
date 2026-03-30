import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// 파일명: login_page.dart
/// 위치: lib/features/auth/presentation/pages/login_page.dart
///
/// 역할:
/// 아이디/비밀번호 로그인 화면
/// 소셜 로그인(Google, Apple, Instagram) 버튼 포함
/// ------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// 비밀번호 표시/숨기기 상태
  bool _obscurePassword = true;

  /// 텍스트 입력 컨트롤러
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 상단 여백
              const SizedBox(height: 80),

              /// 로그인 타이틀
              const Text(
                '로그인',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 28),

              /// ─── 아이디 입력 필드 ───
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: '아이디',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// ─── 비밀번호 입력 필드 ───
              TextField(
                controller: _pwController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFAAAAAA),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// ─── 비밀번호 찾기 링크 ───
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () {
                    // TODO: 비밀번호 찾기 페이지로 이동
                  },
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ─── 로그인 버튼 ───
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 로그인 로직 구현
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
                    '로그인',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              /// ─── 회원가입 안내 ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '처음이신가요? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: 회원가입 페이지로 이동
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// ─── 구분선 ───
              const Divider(color: Color(0xFFDDDDDD), thickness: 1),

              const SizedBox(height: 20),

              /// ─── 소셜 로그인 안내 문구 ───
              const Center(
                child: Text(
                  '다음으로 로그인하기',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              /// ─── 소셜 로그인 아이콘 ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Google
                  _socialButton(
                    color: const Color(0xFFE0E0E0),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                      ),
                    ),
                    onTap: () {
                      // TODO: Google 로그인
                    },
                  ),

                  const SizedBox(width: 16),

                  /// Apple
                  _socialButton(
                    color: const Color(0xFF222222),
                    icon: const Icon(Icons.apple, color: Colors.white, size: 26),
                    onTap: () {
                      // TODO: Apple 로그인
                    },
                  ),

                  const SizedBox(width: 16),

                  /// Instagram
                  _socialButton(
                    color: const Color(0xFFCE4EC1),
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 22),
                    onTap: () {
                      // TODO: Instagram 로그인
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 소셜 로그인 원형 버튼 위젯
  Widget _socialButton({
    required Color color,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}
