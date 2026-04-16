import 'package:frontend/features/cart/data/datasources/cart_api.dart';
import 'package:frontend/features/cart/data/models/cart_model.dart';
import 'package:frontend/app/config/api_client.dart';

class CartRepositoryImpl {
  final CartApi _api;

  CartRepositoryImpl() : _api = CartApi(ApiClient().dio);

  Future<CartModel?> getCart() async => await _api.getCart();

  Future<String> addCartItem({
    required int productId,
    required int quantity,
    required int storeId,
  }) async => await _api.addCartItem(productId: productId, quantity: quantity);

  Future<void> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async => await _api.updateCartItem(cartItemId: cartItemId, quantity: quantity);

  Future<void> deleteCartItem(String cartItemId) async => await _api.deleteCartItem(cartItemId);

  Future<void> clearCart() async => await _api.clearCart();
}