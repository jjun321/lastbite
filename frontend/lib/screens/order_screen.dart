import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import 'cart_screen.dart';

// 소비자 예약주문하기 페이지

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {

  // 장바구니 담기 로직 함수
  void _addToCart(MenuItem item) {
    setState(() {
      // 이미 장바구니에 있는 상품인지 확인
      int index = myCart.indexWhere((cartItem) => cartItem.menu.name == item.name);
      if (index != -1) {
        // 이미 있다면 수량만 증가
        myCart[index].quantity++;
      } else {
        // 없다면 새로 추가
        myCart.add(CartItem(menu: item, quantity: 1));
      }
    });

    // 담겼다는 알림 표시... 필요 없으면 삭제
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name}이(가) 장바구니에 담겼습니다.'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4FA55B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45, height: 45,
                      decoration: const BoxDecoration(color: Color(0xFFECF0F4), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF181C2E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    myStore.name,
                    style: const TextStyle(fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E1E1E)),
                  ),
                ],
              ),
            ),

            // 2. 메뉴 리스트
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // [핵심] 이 숫자를 높여서 카드 사각형의 전체 높이를 줄였습니다.
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: menuList.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(context, menuList[index]);
                },
              ),
            ),

            // 3. 하단 선택 완료 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('선택 완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return Container(
      // 카드 전체 크기를 결정하는 컨테이너
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 내부 요소 크기에 딱 맞춤
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 이미지 영역 (디자인 가이드 반영)
          Container(
            height: 94,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC4C4C4),
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // 2. 상품명 및 추가 버튼 (간격 밀착)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(color: Color(0xFF11A94D), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // 3. 가격 정보 (상단 여백 줄여서 바짝 붙임)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.discountedPrice}원',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '${item.originalPrice}원',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA0A5BA),
                          decoration: TextDecoration.lineThrough
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.discountRate}%',
                      style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFF7622),
                          fontWeight: FontWeight.bold
                      ),
                    ),
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