import 'dart:convert';
import 'package:http/http.dart' as http;

/// Naver Cloud Platform Geocoding API.
/// 운영 단계에서는 백엔드 프록시로 옮기기
class NaverGeocodingService {
  static const _clientId = 'jju5nju4gc';
  static const _clientSecret = 'wU0QezbDc9OWkymr9b404VErqELB5D7s6t9pwEdw';
  static const _endpoint =
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode';

  /// 주소 텍스트 → 좌표 변환
  /// 성공: { 'address': String, 'lat': double, 'lng': double }
  /// 결과 없음: null
  /// 네트워크/파싱 오류: rethrow
  static Future<Map<String, dynamic>?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final uri = Uri.parse('$_endpoint?query=${Uri.encodeQueryComponent(q)}');
      final res = await http.get(
        uri,
        headers: {
          'x-ncp-apigw-api-key-id': _clientId,
          'x-ncp-apigw-api-key': _clientSecret,
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('Naver Geocoding HTTP ${res.statusCode}: ${res.body}');
        return null;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final addresses = body['addresses'] as List?;
      if (addresses == null || addresses.isEmpty) return null;

      final first = addresses.first as Map<String, dynamic>;
      final road = (first['roadAddress'] as String?)?.trim();
      final jibun = (first['jibunAddress'] as String?)?.trim();
      final address = (road != null && road.isNotEmpty)
          ? road
          : (jibun != null && jibun.isNotEmpty ? jibun : q);

      return {
        'address': address,
        'lat': double.parse(first['y'] as String),
        'lng': double.parse(first['x'] as String),
      };
    } catch (e) {
      // ignore: avoid_print
      print('네트워크 오류: $e');
      rethrow;
    }
  }
}
