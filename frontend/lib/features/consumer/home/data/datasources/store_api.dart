import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/data/store_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoreRemoteDataSource {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// [GET /stores] 매장 목록 조회 (전체 가져오기)
  Future<List<StoreModel>> getStores() async {
    try {
      final token = await _getToken();

      // 토큰이 없어도 조회가 가능한 API라면 Options 제외 가능
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get(ApiConfig.stores, options: options);

      if (response.statusCode == 200 && response.data != null) {
        // [DEBUG] 실제 백엔드 응답 구조 확인용 로그
        print('[StoreAPI] 응답 타입: ${response.data.runtimeType}');
        print('[StoreAPI] 응답 raw: ${response.data}');

        List<dynamic> data = [];
        if (response.data is Map &&
            response.data['data'] != null &&
            response.data['data']['stores'] != null) {
          // 실제 백엔드 구조: { success: true, ..., data: { stores: [...] } }
          data = response.data['data']['stores'];
        } else if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'];
        } else if (response.data is Map && response.data['data'] != null) {
          data = response.data['data'] is List ? response.data['data'] : [];
        } else if (response.data is List) {
          data = response.data;
        }

        print('[StoreAPI] 파싱된 가게 수: ${data.length}');
        if (data.isNotEmpty) {
          print('[StoreAPI] 첫 번째 가게 키: ${data[0].keys.toList()}');
        }

        //좌표값(store_lat, store_long)이 String(0.000000)으로 넘어와서 double로 변환해주는 헬퍼 함수 추가
        double? parseDouble(dynamic value) {
          if (value == null) return null;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return null;
        }

        return data.map((json) {
          return StoreModel(
            // 'id', 'pk', 'store_id' 등 백엔드 필드명에 맞게 자동 대응
            id: json['store_id'] ?? json['id'] ?? json['pk'] ?? 0,
            name: json['store_name'] ?? json['name'] ?? '',
            categories:
                (json['categories'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            rating:
                parseDouble(json['rating'] ?? json['average_rating']) ?? 0.0,
            // 영업시간 정보가 today_open/close로 올 경우 합쳐서 표시
            closingTime: json['today_close'] != null
                ? '${json['today_open'] ?? ""} - ${json['today_close']} 마감'
                : (json['closing_time'] ?? json['closingTime'] ?? '영업 정보 없음'),
            isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
            imageUrl: json['image_url'] ?? json['imageUrl'],
            latitude: parseDouble(json['store_lat'] ?? json['latitude']),
            longitude: parseDouble(json['store_long'] ?? json['longitude']),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('가게 목록 조회 에러: $e');
      return [];
    }
  }
}
