import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/services/owner_image_cache.dart';

/// 사장님 계정 관리 페이지
/// 프로필 사진 수정, 아이디/이메일/연락처 확인 및 수정 기능
class OwnerAccountPage extends StatefulWidget {
  const OwnerAccountPage({super.key});

  @override
  State<OwnerAccountPage> createState() => _OwnerAccountPageState();
}

class _OwnerAccountPageState extends State<OwnerAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _profileImage;
  final _authRepo = AuthRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCachedImage();
  }

  // 매장 등록·수정 화면에서 선택한 사진을 프로필 사진으로 동일하게 표시
  Future<void> _loadCachedImage() async {
    final cached = await OwnerImageCache.load();
    if (cached != null && mounted) {
      setState(() => _profileImage = cached);
    }
  }

  Future<void> _loadUserInfo() async {
    // 1. 캐시된 유저 정보로 먼저 렌더링
    UserModel? user = await _authRepo.getUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _nameController.text = user.userName;
          _emailController.text = user.userEmail;
          _phoneController.text = user.userPhone;
        });
      }
    }

    // 2. 백엔드에서 최신 유저 정보(새로운 프로필, 전화번호 등)를 강제로 당겨옴
    UserModel? freshUser = await _authRepo.fetchAndSyncUserProfile();
    if (freshUser != null) {
      if (mounted) {
        setState(() {
          _nameController.text = freshUser.userName;
          _emailController.text = freshUser.userEmail;
          _phoneController.text = freshUser.userPhone;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pop(_profileImage);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // ── 상단 헤더 (뒤로가기 + 타이틀) ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(_profileImage),
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
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final XFile? image = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setState(() {
                                      _profileImage = File(image.path);
                                    });
                                    // 매장 등록·수정·마이페이지와 동일하게 사용하기 위해 로컬 캐시에 저장
                                    await OwnerImageCache.save(image.path);
                                  }
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
                          onPressed: () async {
                            final newName = _nameController.text.trim();
                            final newEmail = _emailController.text.trim();
                            final newPhone = _phoneController.text.trim();

                            // 1. 프로필 이미지 로직 및 스낵바
                            if (_profileImage != null) {
                              try {
                                final imgSuccess = await _authRepo
                                    .uploadProfileImage(_profileImage!);
                                if (imgSuccess && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('프로필 이미지가 성공적으로 저장되었습니다.'),
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('프로필 이미지 저장에 실패했습니다.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('프로필 이미지 저장 중 오류가 발생했습니다.'),
                                    ),
                                  );
                                }
                              }
                            }

                            // 2. 다른 텍스트 데이터 업데이트
                            try {
                              final profileSuccess = await _authRepo
                                  .updateProfile(newName, newEmail, newPhone);
                              if (profileSuccess && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('계정 텍스트 정보가 성공적으로 저장되었습니다.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '유효하지 않은 이메일 형식/전화번호이거나, 중복된 계정 정보입니다.',
                                    ),
                                  ),
                                );
                              }
                            }
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
      style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
    );
  }
}
