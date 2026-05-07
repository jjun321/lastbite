import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/order/data/models/order_model.dart';

class OrderApi {
  final Dio _dio;

  OrderApi(this._dio);

  // 내 주문 목록 조회
  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await _dio.get(ApiConfig.orders);
      final dynamic responseData = response.data['data'];

      if (responseData is List) {
        return responseData.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('❌ OrderApi getOrders Error: $e');
      rethrow;
    }
  }

  // 주문 상세 조회
  Future<OrderModel> getOrderDetail(int orderId) async {
    try {
      final response = await _dio.get(ApiConfig.orderDetail(orderId));
      return OrderModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ OrderApi getOrderDetail Error: $e');
      rethrow;
    }
  }

  // ✅ 추가: 주문 내 특정 상품 상세 조회 (백엔드 OrderItemDetailView 대응)
  Future<OrderItemModel> getOrderItemDetail(int orderId, int productId) async {
    try {
      final response = await _dio.get('${ApiConfig.orders}$orderId/items/$productId/');
      return OrderItemModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ OrderApi getOrderItemDetail Error: $e');
      rethrow;
    }
  }

  // 주문 생성
  Future<OrderModel> createOrder({
    required int storeId,
    required DateTime pickupDt,
    required List<OrderItemModel> items,
  }) async {
    try {
      final response = await _dio.post(ApiConfig.orders, data: {
        'store_id': storeId,
        'pickup_dt': pickupDt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      });
      return OrderModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ OrderApi createOrder Error: $e');
      rethrow;
    }
  }

  // 주문 취소
  Future<void> cancelOrder(int orderId) async {
    try {
      await _dio.patch(ApiConfig.orderCancel(orderId));
    } catch (e) {
      print('❌ OrderApi cancelOrder Error: $e');
      rethrow;
    }
  }
}