import 'package:frontend/app/config/api_client.dart';
import '../datasources/owner_order_api.dart';
import '../models/owner_order_model.dart';

class OwnerOrderRepositoryImpl {
  final OwnerOrderApi _api;

  OwnerOrderRepositoryImpl()
      : _api = OwnerOrderApi(ApiClient().dio);

  /// 📋 들어온 주문
  Future<List<OwnerOrderModel>> getIncomingOrders(int storeId) async {
    try {
      return await _api.getIncomingOrders(storeId);
    } catch (e) {
      print('❌ getIncomingOrders Error: $e');
      rethrow;
    }
  }

  /// 📋 주문 내역
  Future<List<OwnerOrderModel>> getHistoryOrders(int storeId) async {
    try {
      return await _api.getHistoryOrders(storeId);
    } catch (e) {
      print('❌ getHistoryOrders Error: $e');
      rethrow;
    }
  }

  /// 🔍 상세
  Future<Map<String, dynamic>> getOrderDetail(
      int storeId, int orderId) async {
    try {
      return await _api.getOrderDetail(storeId, orderId);
    } catch (e) {
      print('❌ getOrderDetail Error: $e');
      rethrow;
    }
  }

  /// 상태 변경
  Future<void> acceptOrder(int storeId, int orderId) async {
    await _api.acceptOrder(storeId, orderId);
  }

  Future<void> cancelOrder(int storeId, int orderId) async {
    await _api.cancelOrder(storeId, orderId);
  }

  Future<void> completeOrder(int storeId, int orderId) async {
    await _api.completeOrder(storeId, orderId);
  }
}