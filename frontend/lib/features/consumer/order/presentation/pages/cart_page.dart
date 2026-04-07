import 'package:flutter/material.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/features/cart/data/repositories/cart_repository_impl.dart';
import 'reservation_page.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _repo = CartRepositoryImpl();
  CartModel? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cart = await _repo.getCart();
      setState(() { _cart = cart; _isLoading = false; });
    } catch (e) {
      setState(() { _error = '장바구니를 불러오지 못했습니다.'; _isLoading = false; });
    }
  }

  Future<void> _updateQuantity(CartItemModel item, int newQty) async {
    try {
      await _repo.updateCartItem(cartItemId: item.cartItemId, quantity: newQty);
      await _fetchCart(); // 갱신
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수량 변경에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _deleteItem(CartItemModel item) async {
    try {
      await _repo.deleteCartItem(item.cartItemId);
      await _fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 상단 헤더
            Positioned(
              top: 34, left: 24, right: 24,
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
                  const Text('장바구니',
                      style: TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
                ],
              ),
            ),

            // 장바구니 리스트
            Positioned(
              top: 100, left: 21, right: 21, bottom: 200,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _fetchCart,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
                  : (_cart == null || _cart!.items.isEmpty)
                  ? const Center(child: Text('장바구니가 비어있습니다.'))
                  : ListView.builder(
                itemCount: _cart!.items.length,
                itemBuilder: (context, index) =>
                    _buildCartItem(_cart!.items[index]),
              ),
            ),

            // 하단 요약
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(TextSpan(
                            text: '총 수량 ',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF181C2E)),
                            children: [
                              TextSpan(
                                text: '${_cart?.totalQuantity ?? 0}',
                                style: const TextStyle(
                                    color: Color(0xFF4FA55B), fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: '개'),
                            ],
                          )),
                          Row(
                            children: [
                              const Text('총 금액', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 20),
                              Text(
                                '${_cart?.totalPrice ?? 0}원',
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _cart == null || _cart!.items.isEmpty
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservationScreen(cart: _cart!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FA55B),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('예약하기',
                          style: TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (item.quantity > 1) {
                          _updateQuantity(item, item.quantity - 1);
                        } else {
                          _deleteItem(item);
                        }
                      },
                      child: const Icon(Icons.remove_circle_outline, size: 22),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => _updateQuantity(item, item.quantity + 1),
                      child: const Icon(Icons.add_circle_outline, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _deleteItem(item),
                child: const Icon(Icons.cancel_outlined, size: 20, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text('${item.subtotal}원',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}