import 'package:frontend/features/order/data/datasources/order_api.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/app/config/api_client.dart';

class OrderRepositoryImpl {
  final OrderApi _api;

  OrderRepositoryImpl() : _api = OrderApi(ApiClient().dio);

  Future<List<OrderModel>> getOrders() async {
    try {
      // 서버에서 데이터를 가져와서 바로 반환합니다.
      return await _api.getOrders();
    } catch (e) {
      // 에러 로그
      print('❌ 주문 내역 로드 실패: $e');
      rethrow;
    }
  }

  // 나머지 상세 조회, 생성, 취소 로직은 그대로 유지
  Future<OrderModel> getOrderDetail(int orderId) async {
    return await _api.getOrderDetail(orderId);
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

  Future<void> cancelOrder(int orderId) async {
    await _api.cancelOrder(orderId);
  }
}