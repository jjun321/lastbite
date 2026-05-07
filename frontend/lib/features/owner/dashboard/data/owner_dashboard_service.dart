import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/app/config/api_config.dart';

class OwnerDashboardData {
  final String storeName;
  final String totalSales;
  final int incomingCount;
  final int completedCount;
  final List<String> bestSellers;
  final List<String> worstSellers;

  OwnerDashboardData({
    required this.storeName,
    required this.totalSales,
    required this.incomingCount,
    required this.completedCount,
    required this.bestSellers,
    required this.worstSellers,
  });
}

class OwnerDashboardService {
  static const _base = ApiConfig.baseUrl;

  static Future<OwnerDashboardData?> fetch() async {
    try {
      final store = await StoreService.getMyStore();
      if (store == null) return null;

      final storeId = store['store_id'] as int;
      final storeName = (store['store_name'] as String?) ?? '';
      final headers = await AuthService.authHeaders();

      // 병렬 데이터 호출
      final responses = await Future.wait([
        _getMap('/owner/stores/$storeId/orders/', headers),
        _getMap('/owner/stores/$storeId/orders/history/?size=100', headers),
      ]);

      final incoming = responses[0];
      final history = responses[1];

      final incomingCount = (incoming['total'] as num?)?.toInt() ?? 0;
      final allOrders = (history['orders'] as List?) ?? const <dynamic>[];

      int totalSalesNum = 0;
      final productCounts = <String, int>{};

      // 1. 요청하신 대로 S02 상태를 기준으로 필터링
      final completedOrders = allOrders.where((o) {
        final status = (o as Map)['order_status']?.toString().toUpperCase();
        return status == 'S02'; // S02 기준 필터링
      }).toList();

      debugPrint('--- 대시보드 데이터 집계 (S02 기준) ---');
      debugPrint('S02 상태 주문 개수: ${completedOrders.length}');

      // 2. 상품 상세 정보 병렬 호출 및 매출 계산
      final detailFutures = completedOrders.map((o) {
        final orderId = ((o as Map)['order_id'] as num?)?.toInt();
        // 매출액 누적
        totalSalesNum += (o['total_price'] as num?)?.toInt() ?? 0;

        if (orderId != null) {
          return ProductService.getOrderDetail(storeId: storeId, orderId: orderId);
        }
        return Future.value(null);
      }).toList();

      final details = await Future.wait(detailFutures);

      // 3. 상품별 판매 수량 집계
      for (final detail in details) {
        if (detail == null) continue;
        final items = (detail['items'] as List?) ?? const <dynamic>[];
        for (final it in items) {
          final m = it as Map;
          final name = (m['product_name'] as String?) ?? '';
          final qty = (m['quantity'] as num?)?.toInt() ?? 0;
          if (name.isNotEmpty) {
            productCounts[name] = (productCounts[name] ?? 0) + qty;
          }
        }
      }

      // 4. 인기/비인기 상품 정렬
      final entries = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final bestSellers = entries.take(3).map((e) => e.key).toList();
      final worstSellers = entries.length > 3
          ? entries.reversed.take(3).map((e) => e.key).toList()
          : (entries.isNotEmpty ? [entries.last.key] : <String>[]);

      return OwnerDashboardData(
        storeName: storeName,
        totalSales: _formatNumber(totalSalesNum),
        incomingCount: incomingCount,
        completedCount: completedOrders.length,
        bestSellers: bestSellers,
        worstSellers: worstSellers,
      );
    } catch (e) {
      debugPrint('Dashboard Fetch Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _getMap(String path, Map<String, String> headers) async {
    try {
      final res = await http.get(Uri.parse('$_base$path'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return (body['data'] is Map<String, dynamic>) ? body['data'] : {};
        }
      }
    } catch (_) {}
    return {};
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}