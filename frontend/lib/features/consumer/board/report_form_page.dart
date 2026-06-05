import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data/post_service.dart';
import 'package:frontend/features/store/data/repositories/product_repository_impl.dart';
import 'package:frontend/features/store/data/models/product_model.dart';

// 제보하기 페이지 — 리뷰 작성 / 매장 연동 / 상품 선택 / 사진 첨부 / 서버 저장

class ReportFormPage extends StatefulWidget {
  final double? userLat;
  final double? userLong;
  final int? initialStoreId;
  final String? initialStoreName;
  final int? initialProductId;
  final String? initialProductName;

  const ReportFormPage({
    super.key,
    this.userLat,
    this.userLong,
    this.initialStoreId,
    this.initialStoreName,
    this.initialProductId,
    this.initialProductName,
  });

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



  // 선택된 상품 정보
  int? _selectedProductId;
  String? _selectedProductName;

  // 상품 목록
  List<ProductModel> _productResults = [];
  bool _loadingProducts = false;
  bool _showProductList = false;

  final ProductRepositoryImpl _productRepo = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();
    // 초기값 세팅
    if (widget.initialStoreId != null) {
      _selectedStoreId = widget.initialStoreId;
      _selectedStoreName = widget.initialStoreName;
      _storeSearchCtrl.text = widget.initialStoreName ?? '';
    }
    if (widget.initialProductId != null) {
      _selectedProductId = widget.initialProductId;
      _selectedProductName = widget.initialProductName;
      _postNameCtrl.text = widget.initialProductName ?? '할인';
    }
  }

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
    // nginx 업로드 제한(1MB)을 넘지 않도록 해상도·품질을 함께 제한한다.
    // (해상도 제한 없이 imageQuality만 주면 고화질 폰 사진은 1MB를 넘어 413으로 막힌다)
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
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
      // 매장이 바뀌면 상품 초기화
      _selectedProductId = null;
      _selectedProductName = null;
      _productResults = [];
      _showProductList = false;
    });
  }

  // ── 상품 목록 로드 ──
  Future<void> _loadProducts() async {
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 매장을 선택해주세요.')),
      );
      return;
    }
    setState(() {
      _loadingProducts = true;
      _showProductList = true;
    });
    try {
      final products = await _productRepo.getStoreProducts(_selectedStoreId!);
      if (mounted) {
        setState(() {
          _productResults = products;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
          _productResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 목록을 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  // ── 매장 검색 바텀시트 열기 ──
  void _openStoreSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _StoreSearchSheet(
          onSelect: (store) {
            _selectStore(store);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  // ── 상품 선택 ──
  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProductId = product.productId;
      _selectedProductName = product.productName;
      _postNameCtrl.text = product.productName;
      _showProductList = false;
    });
  }

  // ── 제보 등록 ──
  Future<void> _submit() async {
    // 상품이 선택되었으면 postName을 상품명으로, 아니면 기본값 '할인'
    if (_selectedProductName != null && _selectedProductName!.isNotEmpty) {
      _postNameCtrl.text = _selectedProductName!;
    } else if (_postNameCtrl.text.trim().isEmpty) {
      _postNameCtrl.text = '할인';
    }

    setState(() => _submitting = true);

    // 위치: 매장이 선택됐으면 매장 좌표, 아니면 사용자 위치
    final postLat = _selectedStoreLat ?? widget.userLat;
    final postLong = _selectedStoreLong ?? widget.userLong;

    final ok = await PostService.createPost(
      postName: _postNameCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      storeId: _selectedStoreId,
      productId: _selectedProductId,
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
                  // ── 1. 리뷰 작성 (최상단) ──
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
                  const SizedBox(height: 24),

                  // ── 2. 매장명 ──
                  const Center(
                    child: Text(
                      '매장명',
                      style: TextStyle(
                        color: Color(0xFF6B6E82),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 매장 선택 박스 버튼
                  GestureDetector(
                    onTap: _openStoreSearchSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedStoreId != null
                            ? Border.all(color: const Color(0xFF4FA55B), width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedStoreName ?? '매장 리스트 확인',
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedStoreId != null
                                    ? const Color(0xFF32343E)
                                    : const Color(0xFF8E8E8E),
                              ),
                            ),
                          ),
                          if (_selectedStoreId != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStoreId = null;
                                  _selectedStoreName = null;
                                  _selectedStoreLat = null;
                                  _selectedStoreLong = null;
                                  _storeSearchCtrl.clear();
                                  _selectedProductId = null;
                                  _selectedProductName = null;
                                  _productResults = [];
                                  _showProductList = false;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF4FA55B),
                                size: 18,
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF8E8E8E),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 3. 상품명 ──
                  const Center(
                    child: Text(
                      '상품명',
                      style: TextStyle(
                        color: Color(0xFF6B6E82),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 상품 선택 박스 버튼
                  GestureDetector(
                    onTap: _loadProducts,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedProductId != null
                            ? Border.all(color: const Color(0xFF4FA55B), width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedProductName ?? '해당 매장에 있는 상품 확인',
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedProductId != null
                                    ? const Color(0xFF32343E)
                                    : const Color(0xFF8E8E8E),
                              ),
                            ),
                          ),
                          if (_selectedProductId != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProductId = null;
                                  _selectedProductName = null;
                                  _postNameCtrl.text = '할인';
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF4FA55B),
                                size: 18,
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF8E8E8E),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 상품 로딩 중
                  if (_loadingProducts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),

                  // 상품 목록 드롭다운
                  if (_showProductList &&
                      !_loadingProducts &&
                      _productResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 250),
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
                        itemCount: _productResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final product = _productResults[i];
                          return ListTile(
                            leading: product.imgUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      product.imgUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC4C4C4),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Color(0xFF4FA55B),
                                    size: 20,
                                  ),
                            title: Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF32343E),
                              ),
                            ),
                            subtitle: product.productDisPrice != null
                                ? Text(
                                    '${product.productDisPrice}원 (${product.discountRate}% 할인)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9C9BA6),
                                    ),
                                  )
                                : null,
                            onTap: () => _selectProduct(product),
                            dense: true,
                          );
                        },
                      ),
                    ),

                  // 상품 없음 안내
                  if (_showProductList &&
                      !_loadingProducts &&
                      _productResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          _selectedStoreId == null
                              ? '먼저 매장을 선택해주세요.'
                              : '해당 매장에 등록된 상품이 없습니다.',
                          style: const TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── 4. 사진 추가 ──
                  const Text(
                    '사진 추가',
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
                        '선택 완료',
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

/// 매장 검색용 바텀시트 (자체 상태 관리)
class _StoreSearchSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> store) onSelect;

  const _StoreSearchSheet({required this.onSelect});

  @override
  State<_StoreSearchSheet> createState() => _StoreSearchSheetState();
}

class _StoreSearchSheetState extends State<_StoreSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await PostService.searchStores(query);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '매장 검색',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _search,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search, color: Color(0xFF8E8E8E)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? '매장 이름을 입력해주세요'
                          : '검색 결과가 없습니다',
                      style: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final store = _results[i];
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
                        onTap: () => widget.onSelect(store),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
