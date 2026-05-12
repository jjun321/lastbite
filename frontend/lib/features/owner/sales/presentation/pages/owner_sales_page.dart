import 'package:flutter/material.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_product_register_page.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_product_edit_page.dart';
import 'package:frontend/features/owner/sales/presentation/widgets/soldout_confirm_dialog.dart';
import 'package:frontend/features/owner/sales/presentation/widgets/owner_sales_card.dart';

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
    try {
      final store = await StoreService.getMyStore();
      if (store != null && mounted) {
        final sid = store['store_id'] as int;
        final prods = await ProductService.getProducts(sid);
        if (mounted) {
          setState(() {
            _storeId = sid;
            _products = prods;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refresh() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Text(
                      '판매설정',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
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
                    child: GridView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 100, // 버튼 공간 확보
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (ctx, i) {
                        final p = _products[i];
                        final pid = p['product_id'] as int;
                        final isSoldOut =
                            _soldOutIds.contains(pid) ||
                            (p['is_available'] == false);
                        return ProductCard(
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

          // 하단 고정 버튼
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: GestureDetector(
              onTap: _navigateToRegister,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA75A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '상품 추가하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRegister() async {
    if (_storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가게 정보를 찾을 수 없습니다. 먼저 가게를 등록해주세요.')),
      );
      return;
    }
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


