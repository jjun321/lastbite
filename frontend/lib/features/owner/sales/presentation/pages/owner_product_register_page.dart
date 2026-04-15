import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_product_registerok_page.dart';

// 상품 등록 화면
class OwnerProductRegisterPage extends StatefulWidget {
  final int storeId;
  const OwnerProductRegisterPage({super.key, required this.storeId});

  @override
  State<OwnerProductRegisterPage> createState() =>
      _OwnerProductRegisterPageState();
}

class _OwnerProductRegisterPageState extends State<OwnerProductRegisterPage> {
  final _nameCtrl = TextEditingController();
  final _oriCtrl = TextEditingController();
  final _disCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  int _count = 5;
  File? _image;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ProductService.getCategories();
    if (mounted)
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null && mounted) setState(() => _image = File(file.path));
  }

  Future<void> _showImagePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '사진 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            // 갤러리에서 선택
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF4FA75A),
                  size: 24,
                ),
              ),
              title: const Text(
                '갤러리에서 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              subtitle: const Text(
                '휴대폰 사진 갤러리에서 선택합니다',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // 카메라로 촬영
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF4FA75A),
                  size: 24,
                ),
              ),
              title: const Text(
                '카메라로 촬영',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              subtitle: const Text(
                '카메라를 열어 사진을 찍습니다',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final ori = int.tryParse(_oriCtrl.text.trim()) ?? 0;
    final dis = int.tryParse(_disCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      _snack('상품 이름을 입력해주세요.');
      return;
    }
    if (_selectedCategoryId == null) {
      _snack('카테고리를 선택해주세요.');
      return;
    }
    if (ori <= 0) {
      _snack('정가를 입력해주세요.');
      return;
    }
    if (dis <= 0) {
      _snack('할인가를 입력해주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ProductService.createProduct(
        storeId: widget.storeId,
        categoryId: _selectedCategoryId!,
        productName: name,
        oriPrice: ori,
        disPrice: dis,
        count: _count,
      );
      if (res['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerProductRegisterOkPage(),
            ),
          );
        }
      } else {
        _snack(res['message'] ?? '등록에 실패했습니다.');
      }
    } catch (e) {
      _snack('오류: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    '상품 등록',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4FA75A)),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // 상품 이름
                      _label('상품 이름'),
                      _input(_nameCtrl, hint: '000000'),
                      const SizedBox(height: 20),

                      // 카테고리
                      _label('상품 카테고리'),
                      _dropdownCategory(),
                      const SizedBox(height: 20),

                      // 정가
                      _label('정가'),
                      _numInput(_oriCtrl, hint: '000000'),
                      const SizedBox(height: 20),

                      // 할인가
                      _label('할인가'),
                      _numInput(_disCtrl, hint: '000000'),
                      const SizedBox(height: 20),

                      // 상품 수량
                      _label('상품수량'),
                      _counter(),
                      const SizedBox(height: 20),

                      // 상품 사진
                      _label('상품 사진'),
                      const SizedBox(height: 8),
                      _imageBox(),
                      const SizedBox(height: 32),

                      // 저장하기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
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
                                  '상품 등록하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    ),
  );

  Widget _input(TextEditingController ctrl, {String hint = ''}) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F4F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _numInput(TextEditingController ctrl, {String hint = ''}) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F4F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _dropdownCategory() => Container(
    height: 50,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F0),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _selectedCategoryId,
        isExpanded: true,
        hint: const Text(
          '000000',
          style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF666666),
        ),
        items: _categories
            .map<DropdownMenuItem<int>>(
              (c) => DropdownMenuItem(
                value: c['category_id'] as int,
                child: Text(c['category_name'] as String),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedCategoryId = v),
      ),
    ),
  );

  Widget _counter() => Container(
    height: 50,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F0),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$_count',
            style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _count++),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 20,
                color: Color(0xFF666666),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _count = (_count - 1).clamp(0, 999)),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _imageBox() => Row(
    children: [
      GestureDetector(
        onTap: _showImagePicker,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _image != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : const Icon(
                  Icons.add_circle_outline,
                  size: 36,
                  color: Color(0xFFAAAAAA),
                ),
        ),
      ),
    ],
  );
}
