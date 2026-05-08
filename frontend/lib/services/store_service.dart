import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

// 점주 쪽 기능 확인만을 위해 제작된 서비스 페이지 - 추후 소비자와 통합 예정

/// 가게 정보 관련 API 서비스
class StoreService {
  static const _base = kBaseUrl;

  /// 응답을 안전하게 JSON으로 파싱
  /// HTML/빈 문자열/비-JSON 응답이 오면 표준 에러 맵을 만들어 반환
  static Map<String, dynamic> _parseResponse(http.Response res, String tag) {
    final status = res.statusCode;
    final body = res.body;
    // 디버그 로그: status code + body 앞부분
    final preview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
    print('[$tag] status=$status body=$preview');

    final trimmed = body.trimLeft();
    final looksHtml =
        trimmed.startsWith('<') ||
        trimmed.toLowerCase().startsWith('<!doctype');

    if (looksHtml || trimmed.isEmpty) {
      String message;
      if (status == 401 || status == 403) {
        message = '인증이 만료되었어요. 다시 로그인해 주세요. (HTTP $status)';
      } else if (status == 404) {
        message = '요청한 주소를 찾을 수 없어요. (HTTP 404)';
      } else if (status >= 500) {
        message = '서버 오류가 발생했어요. (HTTP $status)';
      } else {
        message = '서버가 JSON 대신 HTML을 반환했어요. ngrok 경고/리다이렉트 가능성. (HTTP $status)';
      }
      return {'success': false, 'message': message, 'data': null};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': '예상치 못한 응답 형식', 'data': decoded};
    } catch (e) {
      return {
        'success': false,
        'message': '응답 파싱 실패: $e (HTTP $status)',
        'data': null,
      };
    }
  }

  // ── 내 가게 조회 (가게가 없으면 null) ──
  static Future<Map<String, dynamic>?> getMyStore() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/owner/stores/'),
        headers: await AuthService.authHeaders(),
      );
      final body = _parseResponse(res, 'getMyStore');
      if (body['success'] == true) {
        final data = body['data'];
        if (data is List && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      print('getMyStore error: $e');
    }
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
      Uri.parse('$_base/owner/stores/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode(body),
    );
    return _parseResponse(res, 'registerStore');
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
      Uri.parse('$_base/owner/stores/$storeId/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode(body),
    );
    return _parseResponse(res, 'updateStore');
  }
}
