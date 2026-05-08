import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';

// 회원가입 화면
// 아이디, 이메일, 연락처, 비밀번호 입력 필드 포함
// 소비자/점주 선택 토글 포함
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();

  /// 비밀번호 표시/숨기기 상태
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  /// 사용자 유형 선택: true = 소비자, false = 점주
  bool _isConsumer = true;

  /// 로딩 상태
  bool _isLoading = false;

  /// 텍스트 입력 컨트롤러
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  /// 아이디 입력 필드 포커스 노드 (포커스 시 테두리 색상 변경)
  final _idFocusNode = FocusNode();
  bool _isIdFocused = false;

  @override
  void initState() {
    super.initState();
    _idFocusNode.addListener(() {
      setState(() {
        _isIdFocused = _idFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _idFocusNode.dispose();
    super.dispose();
  }

  /// 공통 입력 필드 데코레이션
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    bool showBorder = false,
    bool isFocused = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: showBorder
            ? BorderSide(
                color: isFocused
                    ? const Color(0xFF4A7FB5)
                    : const Color(0xFFDDDDDD),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: showBorder
            ? const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: showBorder
            ? const BorderSide(color: Color(0xFF4A7FB5), width: 1.5)
            : BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSignup() async {
    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pw = _pwController.text;
    final pwConfirm = _pwConfirmController.text;

    if (id.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pw.isEmpty ||
        pwConfirm.isEmpty) {
      _showError('모든 필드를 입력해주세요.');
      return;
    }

    if (pw != pwConfirm) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API 명세서에 따라서 user_type은 현재 백엔드 로직에서는 U01로 고정되거나 무시될 수 있으나
      // 프론트의 소비자/점주 선택값은 나중을 위해 상태(_isConsumer)로 들고만 있음
      // 필요 시 백엔드 스펙에 추가되면 요청 payload에 포함해야 함
      // 프론트의 소비자/점주 선택값(_isConsumer)을 반영해 "U01"(소비자), "U02"(점주) 전달
      final request = SignupRequest(
        userName: id,
        userEmail: email,
        userPhone: phone,
        userPassword: pw,
        passwordConfirm: pwConfirm,
        userType: _isConsumer ? "U01" : "U02",
      );

      final response = await _authRepository.signup(request);

      if (response.success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다.')));
        context.go('/login');
      } else if (mounted) {
        _showError(response.message);
      }
    } on DioException catch (e) {
      if (mounted) {
        String errMsg = '회원가입에 실패했습니다. (${e.response?.statusCode})';
        if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map<String, dynamic>;
          if (data.containsKey('message')) {
            errMsg = data['message'];
          }
        }
        _showError(errMsg);
      }
    } catch (e) {
      if (mounted) {
        _showError('회원가입 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              const SizedBox(height: 60),

              /// 회원가입 타이틀
              const Text(
                '회원가입',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 28),

              /// ─── 아이디 입력 필드 ───
              const Text(
                '아이디',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _idController,
                focusNode: _idFocusNode,
                decoration: _inputDecoration(
                  hintText: '문자 또는 숫자 4~10자',
                  showBorder: true,
                  isFocused: _isIdFocused,
                ),
              ),

              const SizedBox(height: 20),

              /// ─── 이메일 주소 입력 필드 ───
              const Text(
                '이메일 주소',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(hintText: 'name@email.com'),
              ),

              const SizedBox(height: 20),

              /// ─── 연락처 입력 필드 ───
              const Text(
                '연락처',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(hintText: '010-0000-0000'),
              ),

              const SizedBox(height: 20),

              /// ─── 비밀번호 입력 필드 ───
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pwController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  hintText: '영문 대소문자, 하나 이상의 숫자를 포함하여 8자 이상',
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

              const SizedBox(height: 14),

              /// ─── 비밀번호 확인 입력 필드 ───
              TextField(
                controller: _pwConfirmController,
                obscureText: _obscurePasswordConfirm,
                decoration: _inputDecoration(
                  hintText: '비밀번호 확인',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFAAAAAA),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePasswordConfirm = !_obscurePasswordConfirm;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              /// ─── 소비자/점주 선택 토글 ───
              Row(
                children: [
                  /// 소비자 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isConsumer = true;
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isConsumer
                              ? const Color(0xFF4FA75A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: _isConsumer
                              ? null
                              : Border.all(
                                  color: const Color(0xFFDDDDDD),
                                  width: 1,
                                ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '소비자',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isConsumer
                                ? Colors.white
                                : const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 점주 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isConsumer = false;
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isConsumer
                              ? Colors.white
                              : const Color(0xFF4FA75A),
                          borderRadius: BorderRadius.circular(28),
                          border: _isConsumer
                              ? Border.all(
                                  color: const Color(0xFFDDDDDD),
                                  width: 1,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '점주',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isConsumer
                                ? const Color(0xFFDDDDDD)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ─── 가입 완료 버튼 ───
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup, // 회원가입 로직
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA75A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    disabledBackgroundColor: const Color(
                      0xFF4FA75A,
                    ).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '가입 완료',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              /// ─── 로그인 안내 링크 ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go('/login');
                    },
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
}
