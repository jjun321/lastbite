import 'package:frontend/features/cart/data/datasources/cart_api.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/app/config/api_client.dart';
import 'package:dio/dio.dart';

class CartRepositoryImpl {
  final CartApi _api;

  CartRepositoryImpl() : _api = CartApi(ApiClient().dio);

  Future<CartModel?> getCart() async => await _api.getCart();

  Future<String> addCartItem({
    required int productId,
    required int quantity,
    required int storeId,
  }) async {
    try {
      // ✅ 1차 시도
      return await _api.addCartItem(
        productId: productId,
        quantity: quantity,
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? '';

      print('⚠️ addCartItem 실패 감지: $errorMessage');

      // 🚨 다른 매장 상품 에러 감지
      if (errorMessage.toString().contains('다른 매장의 상품')) {
        print('🧹 장바구니 자동 비우기 실행');

        try {
          // ✅ 장바구니 비우기
          await _api.clearCart();

          print('🔁 장바구니 비운 후 재시도');

          // ✅ 재시도
          return await _api.addCartItem(
            productId: productId,
            quantity: quantity,
          );
        } catch (retryError) {
          print('❌ 재시도 실패: $retryError');
          rethrow;
        }
      }

      // ❗ 다른 에러는 그대로 던짐
      rethrow;
    }
  }

  Future<void> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async => await _api.updateCartItem(
    cartItemId: cartItemId,
    quantity: quantity,
  );

  Future<void> deleteCartItem(String cartItemId) async =>
      await _api.deleteCartItem(cartItemId);

  Future<void> clearCart() async => await _api.clearCart();
}