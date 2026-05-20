import 'package:frontend/features/order/data/datasources/order_api.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/app/config/api_client.dart';

class OrderRepositoryImpl {
  final OrderApi _api;

  OrderRepositoryImpl() : _api = OrderApi(ApiClient().dio);

  Future<List<OrderModel>> getOrders() async {
    return await _api.getOrders();
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    return await _api.getOrderDetail(orderId);
  }

  // ✅ 추가: 주문 상품 상세 정보 가져오기
  Future<OrderItemModel> getOrderItemDetail(int orderId, int productId) async {
    return await _api.getOrderItemDetail(orderId, productId);
  }

  Future<OrderModel> createOrder({
    required int storeId,
    required DateTime pickupDt,
    required List<OrderItemModel> items,
  }) async {
    return await _api.createOrder(
      storeId: storeId,
      pickupDt: pickupDt,
      items: items,
    );
  }

  // 재주문 — POST /orders/{order_id}/reorder/
  Future<Map<String, dynamic>> reorder(int orderId) async {
    return await _api.reorder(orderId);
  }

  Future<void> cancelOrder(int orderId) async {
    await _api.cancelOrder(orderId);
  }
}