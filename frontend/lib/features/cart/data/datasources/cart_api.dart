import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';

class CartApi {
  final Dio _dio;

  CartApi(this._dio);

  // 장바구니 조회
  Future<CartModel?> getCart() async {
    try {
      final response = await _dio.get(ApiConfig.cart);
      if (response.data == null || response.data['data'] == null) return null;
      return CartModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ CartApi getCart Error: $e');
      return null;
    }
  }

  // 상품 추가
  Future<String> addCartItem({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post(ApiConfig.cartItems, data: {
        'product_id': productId,
        'quantity': quantity,
      });
      return response.data['data']['cart_item_id'].toString();
    } catch (e) {
      print('❌ CartApi addCartItem Error: $e');
      rethrow;
    }
  }

  // 수량 변경
  Future<void> updateCartItem({required String cartItemId, required int quantity}) async {
    try {
      print('🚀 수량 변경 시도: ID=$cartItemId, 수량=$quantity');
      print('🔗 요청 URL: ${ApiConfig.cartItem(cartItemId)}');

      final response = await _dio.patch(
          ApiConfig.cartItem(cartItemId),
          data: {'quantity': quantity}
      );

      print('✅ 서버 응답: ${response.data}');
    } on DioException catch (e) {
      // DioException 객체 e를 사용하여 로그 출력 (경고 방지)
      print('❌ 장바구니 수정 실패: ${e.message}');
      rethrow;
    }
  }

  // 상품 삭제
  Future<void> deleteCartItem(String cartItemId) async {
    try {
      await _dio.delete(ApiConfig.cartItem(cartItemId));
    } catch (e) {
      print('❌ CartApi deleteCartItem Error: $e');
      rethrow;
    }
  }

  // 장바구니 비우기
  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiConfig.cart);
    } catch (_) {
      // ✅ 수정 포인트: e 대신 _를 사용하여 사용하지 않는 변수임을 명시 (Warning 해결)
      print('❌ CartApi clearCart Error');
      rethrow;
    }
  }
}