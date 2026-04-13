import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

// 점주 쪽 기능 확인만을 위해 제작된 서비스 페이지 - 추후 소비자와 통합 예정

/// 가게 정보 관련 API 서비스
class StoreService {
  static const _base = kBaseUrl;

  // ── 내 가게 조회 (가게가 없으면 null) ──
  static Future<Map<String, dynamic>?> getMyStore() async {
    final res = await http.get(
      Uri.parse('$_base/stores/my/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) return body['data'] as Map<String, dynamic>;
    return null; // 404 = 가게 없음
  }

  // ── 가게 등록 ──
  static Future<Map<String, dynamic>> registerStore({
    required String storeName,
    required String storeAddress,
    double? storeLat,
    double? storeLong,
    String storeDesc = '',
    String? openTime, // "HH:mm"
    String? closeTime, // "HH:mm"
    List<String> offDates = const [], // ["YYYY-MM-DD", ...]
  }) async {
    final body = <String, dynamic>{
      'store_name': storeName,
      'store_address': storeAddress,
      if (storeLat != null) 'store_lat': storeLat,
      if (storeLong != null) 'store_long': storeLong,
      'store_desc': storeDesc,
      if (openTime != null) 'open_time': openTime,
      if (closeTime != null) 'close_time': closeTime,
      'off_dates': offDates,
    };

    final res = await http.post(
      Uri.parse('$_base/stores/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 가게 정보 수정 ──
  static Future<Map<String, dynamic>> updateStore({
    required int storeId,
    String? storeName,
    String? storeAddress,
    double? storeLat,
    double? storeLong,
    String? storeDesc,
    String? openTime,
    String? closeTime,
    List<String>? offDates,
  }) async {
    final body = <String, dynamic>{
      if (storeName != null) 'store_name': storeName,
      if (storeAddress != null) 'store_address': storeAddress,
      if (storeLat != null) 'store_lat': storeLat,
      if (storeLong != null) 'store_long': storeLong,
      if (storeDesc != null) 'store_desc': storeDesc,
      if (openTime != null) 'open_time': openTime,
      if (closeTime != null) 'close_time': closeTime,
      if (offDates != null) 'off_dates': offDates,
    };

    final res = await http.put(
      Uri.parse('$_base/stores/$storeId/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
