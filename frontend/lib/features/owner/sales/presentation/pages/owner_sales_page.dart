import 'package:flutter/material.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_product_register_page.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_product_edit_page.dart';
import 'package:frontend/features/owner/sales/presentation/widgets/soldout_confirm_dialog.dart';

// 판매설정 화면
class OwnerSalesPage extends StatefulWidget {
  const OwnerSalesPage({super.key});

  @override
  State<OwnerSalesPage> createState() => _OwnerSalesPageState();
}

class _OwnerSalesPageState extends State<OwnerSalesPage> {
  int? _storeId;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  // 품절 처리된 상품 ID 목록
  final Set<int> _soldOutIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final store = await StoreService.getMyStore();
    if (store != null && mounted) {
      final sid = store['store_id'] as int;
      final prods = await ProductService.getProducts(sid);
      setState(() {
        _storeId = sid;
        _products = prods;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '판매설정',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToRegister(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FA75A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            '상품 추가하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
            else if (_products.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Color(0xFFCCCCCC),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '등록된 상품이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF999999),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '상품 추가하기 버튼을 눌러 등록해보세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF4FA75A),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      final pid = p['product_id'] as int;
                      final isSoldOut =
                          _soldOutIds.contains(pid) ||
                          (p['is_available'] == false);
                      return _ProductCard(
                        product: p,
                        isSoldOut: isSoldOut,
                        onEdit: () => _navigateToEdit(p),
                        onSoldOut: () => _showSoldOutSheet(pid, i),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToRegister() async {
    if (_storeId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerProductRegisterPage(storeId: _storeId!),
      ),
    );
    _loadData();
  }

  Future<void> _navigateToEdit(Map<String, dynamic> product) async {
    if (_storeId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OwnerProductEditPage(storeId: _storeId!, product: product),
      ),
    );
    _loadData();
  }

  void _showSoldOutSheet(int productId, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SoldOutConfirmSheet(
        onConfirm: () async {
          Navigator.pop(context);
          await ProductService.setSoldOut(
            storeId: _storeId!,
            productId: productId,
          );
          setState(() => _soldOutIds.add(productId));
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

/// 상품 카드 위젯
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isSoldOut;
  final VoidCallback onEdit;
  final VoidCallback onSoldOut;

  const _ProductCard({
    required this.product,
    required this.isSoldOut,
    required this.onEdit,
    required this.onSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    final oriPrice = product['product_ori_price'] ?? 0;
    final disPrice = product['product_dis_price'] ?? 0;
    final rate = product['discount_rate'] ?? 0;
    final imgUrl = product['img_url'] as String?;

    return Opacity(
      opacity: isSoldOut ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 상품 이미지
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF0F4F0),
                ),
                child: imgUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imgUrl, fit: BoxFit.cover),
                      )
                    : const Icon(
                        Icons.fastfood_outlined,
                        size: 32,
                        color: Color(0xFFBBBBBB),
                      ),
              ),
              const SizedBox(width: 14),

              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isSoldOut)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '품절',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isSoldOut) const SizedBox(width: 6),
                        Text(
                          product['product_name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['category_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (rate > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4FA75A,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$rate%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4FA75A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (rate > 0) const SizedBox(width: 6),
                        Text(
                          '${_format(disPrice)}원',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_format(oriPrice)}원',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 액션 버튼
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF4FA75A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onSoldOut,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
