import 'package:frontend/app/config/api_client.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/owner/order_manage/data/models/owner_order_model.dart';
import 'package:frontend/services/store_service.dart';

class OrderService {
  final _dio = ApiClient().dio;
  int? _storeId;

  Future<int?> _getStoreId() async {
    if (_storeId != null) return _storeId;
    final store = await StoreService.getMyStore();
    if (store != null && store['store_id'] != null) {
      _storeId = store['store_id'];
      return _storeId;
    }
    return null;
  }

  /// 📌 들어온 주문 목록 (OwnerOrderModel 리스트 반환)
  Future<List<OwnerOrderModel>> fetchOrders() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return [];
      final res = await _dio.get(ApiConfig.ownerOrders(storeId));
      final List list = res.data['data']['orders'] ?? [];
      return list.map((e) => OwnerOrderModel.fromJson(e)).toList();
    } catch (e) {
      print('fetchOrders error: $e');
      return [];
    }
  }

  /// 📌 주문 내역
  Future<List<OwnerOrderModel>> fetchHistory() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return [];
      final res = await _dio.get(ApiConfig.ownerOrderHistory(storeId));
      final List list = res.data['data']['orders'] ?? [];
      return list.map((e) => OwnerOrderModel.fromJson(e)).toList();
    } catch (e) {
      print('fetchHistory error: $e');
      return [];
    }
  }

  /// 📌 주문 상세
  Future<OwnerOrderModel?> fetchOrderDetail(int orderId) async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return null;
      final res = await _dio.get(ApiConfig.ownerOrderDetail(storeId, orderId));
      return OwnerOrderModel.fromJson(res.data['data']);
    } catch (e) {
      print('fetchOrderDetail error: $e');
      return null;
    }
  }

  /// 📌 주문 수락
  Future<bool> acceptOrder(int orderId) async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return false;
      await _dio.patch(ApiConfig.ownerOrderAccept(storeId, orderId));
      return true;
    } catch (e) {
      print('acceptOrder error: $e');
      return false;
    }
  }

  /// 📌 주문 취소
  Future<bool> cancelOrder(int orderId) async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return false;
      await _dio.patch(ApiConfig.ownerOrderCancel(storeId, orderId));
      return true;
    } catch (e) {
      print('cancelOrder error: $e');
      return false;
    }
  }
}