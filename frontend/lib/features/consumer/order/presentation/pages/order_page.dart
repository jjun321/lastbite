import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:frontend/features/store/data/repositories/product_repository_impl.dart';
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

  Future<void> _addToCart(ProductModel item) async {
    try {
      print("--- 장바구니 담기 시도 ---");
      print("가게 ID: ${widget.storeId}, 상품 ID: ${item.productId}");

      // ✅ 수정: addCartItem을 호출할 때 storeId도 함께 보내야 합니다.
      // (CartRepository의 addCartItem 메서드에 storeId 파라미터가 있다고 가정)
      await _cartRepo.addCartItem(
        productId: item.productId,
        quantity: 1,
        storeId: widget.storeId, // 👈 만약 레포지토리에 이 필드가 있다면 추가하세요!
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName}이(가) 장바구니에 담겼습니다.'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4FA55B),
          ),
        );
      }
    } catch (e) {
      print("❌ 장바구니 담기 실패 상세 원인: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 화면에도 에러 내용을 포함해서 띄워줍니다.
            content: Text('장바구니 담기 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

            // 상품 목록
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
                      childAspectRatio: 0.85,
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

            // 선택 완료 버튼
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Container(
            height: 94,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              color: item.imgUrl != null ? null : const Color(0xFFC4C4C4),
              borderRadius: BorderRadius.circular(5),
              image: item.imgUrl != null
                  ? DecorationImage(
                  image: NetworkImage(item.imgUrl!), fit: BoxFit.cover)
                  : null,
            ),
          ),

          // 상품명 + 담기 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(item.productName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                        color: Color(0xFF11A94D), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // 가격
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.productDisPrice ?? 0}원',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text('${item.productOriPrice ?? 0}원',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFA0A5BA),
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 4),
                    Text('${item.discountRate}%',
                        style: const TextStyle(
                            fontSize: 18, color: Color(0xFFFF7622),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}