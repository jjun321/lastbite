import 'package:dio/dio.dart';
import 'package:frontend/features/owner/order_manage/data/models/owner_order_model.dart';
import '../../../../../../app/config/api_config.dart';

class OwnerOrderApi {
  final Dio _dio;

  OwnerOrderApi(this._dio);

  /// 📋 들어온 주문 (S01)
  Future<List<OwnerOrderModel>> getIncomingOrders(int storeId) async {
    final response = await _dio.get(
      ApiConfig.ownerOrders(storeId),
    );

    final List list = response.data['data']['orders'] ?? [];

    return list.map((e) => OwnerOrderModel.fromJson(e)).toList();
  }

  /// 📋 주문 내역 (S02, S03, S04)
  Future<List<OwnerOrderModel>> getHistoryOrders(int storeId) async {
    final response = await _dio.get(
      ApiConfig.ownerOrderHistory(storeId),
    );

    final List list = response.data['data']['orders'] ?? [];

    return list.map((e) => OwnerOrderModel.fromJson(e)).toList();
  }

  /// 🔍 주문 상세
  Future<Map<String, dynamic>> getOrderDetail(
      int storeId, int orderId) async {
    final response = await _dio.get(
      ApiConfig.ownerOrderDetail(storeId, orderId),
    );

    return response.data['data'];
  }

  /// ✅ 주문 수락 (S01 → S02)
  Future<void> acceptOrder(int storeId, int orderId) async {
    await _dio.patch(
      ApiConfig.ownerOrderAccept(storeId, orderId),
    );
  }

  /// ❌ 주문 취소 (S01 → S04)
  Future<void> cancelOrder(int storeId, int orderId) async {
    await _dio.patch(
      ApiConfig.ownerOrderCancel(storeId, orderId),
    );
  }

  /// ✔️ 픽업 완료 (S02 → S03)
  Future<void> completeOrder(int storeId, int orderId) async {
    await _dio.patch(
      ApiConfig.ownerOrderComplete(storeId, orderId),
    );
  }
}