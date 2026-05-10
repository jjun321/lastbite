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
      final response = await _dio.post(
        ApiConfig.cartItems,
        data: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
      return response.data['data']['cart_item_id'].toString();
    } catch (e) {
      print('❌ CartApi addCartItem Error: $e');
      rethrow;
    }
  }

  // 수량 변경 (최종 수정본)
  Future<void> updateCartItem({required String cartItemId, required int quantity}) async {
    try {
      final path = ApiConfig.cartItem(cartItemId); // 결과: /cart/items/UUID/
      print('🚀 최종 요청 경로: $path (수량: $quantity)');

      final response = await _dio.patch(
        path, // Dio가 가지고 있는 baseUrl과 자동으로 합쳐집니다.
        data: {'quantity': quantity},
      );
      print('✅ 수정 성공: ${response.data}');
    } on DioException catch (e) {
      print('❌ 수량 변경 실패: ${e.response?.statusCode}');
      print('❌ 에러 상세 내용: ${e.response?.data}');
      rethrow;
    }
  }

  // 상품 삭제 (최종 수정본)
  Future<void> deleteCartItem(String cartItemId) async {
    try {
      final path = ApiConfig.cartItem(cartItemId);
      print('🚀 삭제 요청 경로: $path');

      await _dio.delete(path);
      print('✅ 삭제 성공');
    } on DioException catch (e) {
      print('❌ 삭제 실패 상세: ${e.response?.data}');
      rethrow;
    }
  }

  // 장바구니 비우기
  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiConfig.cart);
    } catch (e) {
      print('❌ CartApi clearCart Error: $e');
      rethrow;
    }
  }
}