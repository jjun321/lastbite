import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/order/data/models/order_model.dart'; // 경로 확인 필요

class OrderApi {
  final Dio _dio;

  // 생성자를 통해 주입받음
  OrderApi(this._dio);

// GET /orders/ — 내 주문 목록
  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get(ApiConfig.orders);

    // response.data 자체가 List인 경우
    if (response.data is List) {
      return (response.data as List)
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }

    // 만약 예전처럼 특정 키 안에 들어있다면 (안전장치)
    final dynamic data = response.data['data'];
    final List<dynamic> orders = (data is Map) ? data['orders'] : data;

    return orders.map((e) => OrderModel.fromJson(e)).toList();
  }

  // GET /orders/{order_id}/ — 주문 상세
  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await _dio.get(ApiConfig.orderDetail(orderId));
    return OrderModel.fromJson(response.data['data']);
  }

  // POST /orders/ — 주문 생성
  Future<OrderModel> createOrder({
    required int storeId,
    required DateTime pickupDt,
    required List<OrderItemModel> items,
  }) async {
    final response = await _dio.post(ApiConfig.orders, data: {
      'store_id': storeId,
      'pickup_dt': pickupDt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    });
    return OrderModel.fromJson(response.data['data']);
  }

  // PATCH /orders/{order_id}/cancel — 주문 취소
  Future<void> cancelOrder(int orderId) async {
    await _dio.patch(ApiConfig.orderCancel(orderId));
  }
}