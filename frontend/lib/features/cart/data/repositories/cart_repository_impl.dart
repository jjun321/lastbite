import 'package:frontend/features/cart/data/datasources/cart_api.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/app/config/api_client.dart';
import 'package:dio/dio.dart';

// ✅ 장바구니 추가 결과를 정의하는 enum
enum AddCartResult { success, differentStore, failure }

class CartRepositoryImpl {
  final CartApi _api;

  CartRepositoryImpl() : _api = CartApi(ApiClient().dio);

  Future<CartModel?> getCart() async => await _api.getCart();

  // ✅ 리턴 타입을 Future<AddCartResult>로 변경하여 UI에 상태 전달
  Future<AddCartResult> addCartItem({
    required int productId,
    required int quantity,
    required int storeId,
  }) async {
    try {
      await _api.addCartItem(
        productId: productId,
        quantity: quantity,
      );
      return AddCartResult.success;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? '';

      // 🚨 서버 에러 메시지에 '다른 매장'이 포함된 경우
      if (errorMessage.toString().contains('다른 매장의 상품')) {
        return AddCartResult.differentStore;
      }

      print('❌ 장바구니 추가 실패: $errorMessage');
      return AddCartResult.failure;
    } catch (e) {
      print('❌ 알 수 없는 에러: $e');
      return AddCartResult.failure;
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

  // 장바구니 전체 초기화
  Future<void> clearCart() async => await _api.clearCart();
}