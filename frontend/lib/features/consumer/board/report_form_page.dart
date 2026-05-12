import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data/post_service.dart';

// 제보하기 페이지 — 리뷰 작성 / 매장 연동 / 사진 첨부 / 서버 저장

class ReportFormPage extends StatefulWidget {
  final double? userLat;
  final double? userLong;

  const ReportFormPage({super.key, this.userLat, this.userLong});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _contentCtrl = TextEditingController();
  final _storeSearchCtrl = TextEditingController();
  final _postNameCtrl = TextEditingController(text: '할인');

  File? _imageFile;
  bool _submitting = false;

  // 선택된 매장 정보
  int? _selectedStoreId;
  String? _selectedStoreName;
  double? _selectedStoreLat;
  double? _selectedStoreLong;

  // 매장 검색 결과
  List<Map<String, dynamic>> _storeResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _storeSearchCtrl.dispose();
    _postNameCtrl.dispose();
    super.dispose();
  }

  // ── 이미지 선택 ──
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // ── 매장 검색 (debounce 없이 단순 검색) ──
  Future<void> _searchStore(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _storeResults = [];
        _selectedStoreId = null;
        _selectedStoreName = null;
        _selectedStoreLat = null;
        _selectedStoreLong = null;
      });
      return;
    }
    setState(() => _searching = true);
    final results = await PostService.searchStores(query);
    if (mounted) {
      setState(() {
        _storeResults = results;
        _searching = false;
      });
    }
  }

  // ── 매장 선택 ──
  void _selectStore(Map<String, dynamic> store) {
    setState(() {
      _selectedStoreId = store['store_id'] as int?;
      _selectedStoreName = store['store_name'] as String?;
      _selectedStoreLat = (store['store_lat'] as num?)?.toDouble();
      _selectedStoreLong = (store['store_long'] as num?)?.toDouble();
      _storeSearchCtrl.text = _selectedStoreName ?? '';
      _storeResults = [];
    });
  }

  // ── 제보 등록 ──
  Future<void> _submit() async {
    if (_postNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제보 이름을 입력해주세요.')));
      return;
    }

    setState(() => _submitting = true);

    // 위치: 매장이 선택됐으면 매장 좌표, 아니면 사용자 위치
    final postLat = _selectedStoreLat ?? widget.userLat;
    final postLong = _selectedStoreLong ?? widget.userLong;

    final ok = await PostService.createPost(
      postName: _postNameCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      storeId: _selectedStoreId,
      postLat: postLat,
      postLong: postLong,
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('제보가 등록되었습니다!')));
        Navigator.pop(context, true); // true = 새로 작성됨
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제보 등록에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 상단 핸들
          const SizedBox(height: 12),
          Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '제보하기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),

          // 스크롤 본문
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: bottomInset + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 제보 이름 ──
                  const Text(
                    '제보 이름',
                    style: TextStyle(color: Color(0xFF6B6E82), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _postNameCtrl,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: '예) 할인, 품절 알림, 이벤트',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F5FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF4FA55B),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 리뷰 작성 ──
                  const Text(
                    '리뷰 작성',
                    style: TextStyle(color: Color(0xFF6B6E82), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: '리뷰를 작성해주세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF4FA55B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 매장명 입력 + 검색 ──
                  const Text(
                    '매장명',
                    style: TextStyle(color: Color(0xFF6B6E82), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _storeSearchCtrl,
                    maxLines: 1,
                    onChanged: _searchStore,
                    decoration: InputDecoration(
                      hintText: '매장 이름을 검색해주세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F5FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF4FA55B),
                          width: 1,
                        ),
                      ),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (_selectedStoreId != null
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4FA55B),
                                  )
                                : const Icon(
                                    Icons.search,
                                    color: Color(0xFF8E8E8E),
                                  )),
                    ),
                  ),

                  // 검색 결과 드롭다운
                  if (_storeResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _storeResults.length > 5
                            ? 5
                            : _storeResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final store = _storeResults[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.store,
                              color: Color(0xFF4FA55B),
                              size: 20,
                            ),
                            title: Text(
                              store['store_name'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF32343E),
                              ),
                            ),
                            subtitle: store['store_address'] != null
                                ? Text(
                                    store['store_address'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9C9BA6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectStore(store),
                            dense: true,
                          );
                        },
                      ),
                    ),

                  // 선택된 매장 표시
                  if (_selectedStoreId != null && _storeResults.isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF4FA55B),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '지도에서 연동됨: $_selectedStoreName',
                              style: const TextStyle(
                                color: Color(0xFF4FA55B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStoreId = null;
                                _selectedStoreName = null;
                                _selectedStoreLat = null;
                                _selectedStoreLong = null;
                                _storeSearchCtrl.clear();
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF4FA55B),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── 사진 첨부 ──
                  const Text(
                    '사진 첨부',
                    style: TextStyle(color: Color(0xFF32343E), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 130,
                        height: 142,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _imageFile != null
                                ? const Color(0xFF4FA55B)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: _imageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_imageFile!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _imageFile = null),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.add_circle,
                                size: 30,
                                color: Color(0xFF1E1E1E),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 고정 등록 버튼
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  disabledBackgroundColor: const Color(
                    0xFF4FA55B,
                  ).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '제보 등록',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
