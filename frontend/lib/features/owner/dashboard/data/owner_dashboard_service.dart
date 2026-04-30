import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/services/product_service.dart';

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
  static const _base = kBaseUrl;

  static Future<OwnerDashboardData?> fetch() async {
    final store = await StoreService.getMyStore();
    if (store == null) return null;

    final storeId = store['store_id'] as int;
    final storeName = (store['store_name'] as String?) ?? '';

    final headers = await AuthService.authHeaders();

    final incoming = await _getMap('/owner/stores/$storeId/orders/', headers);
    final history = await _getMap(
      '/owner/stores/$storeId/orders/history/?size=50',
      headers,
    );
    final completedHistory = await _getMap(
      '/owner/stores/$storeId/orders/history/?status=S03&size=50',
      headers,
    );

    final incomingCount = (incoming['total'] as num?)?.toInt() ?? 0;
    final completedCount = (history['total'] as num?)?.toInt() ?? 0;

    final completedOrders =
        (completedHistory['orders'] as List?) ?? const <dynamic>[];

    int totalSalesNum = 0;
    final productCounts = <String, int>{};

    for (final o in completedOrders) {
      totalSalesNum += ((o as Map)['total_price'] as num?)?.toInt() ?? 0;

      final orderId = (o['order_id'] as num?)?.toInt();
      if (orderId == null) continue;

      final detail = await ProductService.getOrderDetail(
        storeId: storeId,
        orderId: orderId,
      );
      if (detail == null) continue;

      final items = (detail['items'] as List?) ?? const <dynamic>[];
      for (final it in items) {
        final m = it as Map;
        final name = (m['product_name'] as String?) ?? '';
        if (name.isEmpty) continue;
        final qty = (m['quantity'] as num?)?.toInt() ?? 0;
        productCounts[name] = (productCounts[name] ?? 0) + qty;
      }
    }

    final entries = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestSellers = entries.take(3).map((e) => e.key).toList();
    final worstSellers = entries.reversed.take(3).map((e) => e.key).toList();

    return OwnerDashboardData(
      storeName: storeName,
      totalSales: _formatNumber(totalSalesNum),
      incomingCount: incomingCount,
      completedCount: completedCount,
      bestSellers: bestSellers,
      worstSellers: worstSellers,
    );
  }

  static Future<Map<String, dynamic>> _getMap(
    String path,
    Map<String, String> headers,
  ) async {
    try {
      final res = await http.get(Uri.parse('$_base$path'), headers: headers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}
    return const {};
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
