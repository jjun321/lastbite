import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:frontend/features/store/data/repositories/product_repository_impl.dart';
import 'package:frontend/features/consumer/order/presentation/widgets/cart_reset_dialog.dart';
import 'cart_page.dart';

class OrderScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const OrderScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _productRepo = ProductRepositoryImpl();
  final _cartRepo = CartRepositoryImpl();

  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productRepo.getStoreProducts(widget.storeId);
  }

  // 장바구니 담기 핵심 로직
  Future<void> _addToCart(ProductModel item) async {
    final result = await _cartRepo.addCartItem(
      productId: item.productId,
      quantity: 1,
      storeId: widget.storeId,
    );

    if (result == AddCartResult.success) {
      _showSnackBar('${item.productName}이(가) 장바구니에 담겼습니다.', const Color(0xFF4FA55B));
    }
    else if (result == AddCartResult.differentStore) {
      _showResetDialog(item);
    }
    else {
      _showSnackBar('장바구니 담기 실패. 다시 시도해주세요.', Colors.red);
    }
  }

  void _showResetDialog(ProductModel item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CartResetDialog(
        onConfirm: () async {
          Navigator.pop(context);
          await _cartRepo.clearCart();
          await _addToCart(item);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          backgroundColor: bgColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45, height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF0F4), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Color(0xFF181C2E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(widget.storeName,
                      style: const TextStyle(
                          fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen())),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E1E1E)),
                  ),
                ],
              ),
            ),

            // 상품 목록 리스트
            Expanded(
              child: FutureBuilder<List<ProductModel>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('상품을 불러오지 못했습니다.'),
                          TextButton(
                            onPressed: () => setState(() {
                              _productsFuture = _productRepo.getStoreProducts(widget.storeId);
                            }),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(child: Text('등록된 상품이 없습니다.'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72, // 높이를 더 확보하여 오버플로우 방지
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        _buildMenuItem(context, products[index]),
                  );
                },
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const CartScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('선택 완료',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ProductModel item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상품 이미지
          Container(
            height: 90,
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC4C4C4),
              borderRadius: BorderRadius.circular(5),
              image: item.imgUrl != null
                  ? DecorationImage(image: NetworkImage(item.imgUrl!), fit: BoxFit.cover)
                  : null,
            ),
          ),

          // 이름 및 추가 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                        color: Color(0xFF11A94D), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // 가격 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${item.productDisPrice ?? 0}원',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text('${item.productOriPrice ?? 0}원',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFFA0A5BA),
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 4),
                        Text('${item.discountRate}%',
                            style: const TextStyle(
                                fontSize: 16, color: Color(0xFFFF7622),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}