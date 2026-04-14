import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/data/store_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoriteRemoteDataSource {
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

  /// [POST /stores/{store_id}/favorite] 즐겨찾기 추가
  Future<bool> addFavorite(int storeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('[FavoriteAPI] addFavorite: 토큰 없음');
        return false;
      }

      final response = await _dio.post(
        ApiConfig.toggleFavorite(storeId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('[FavoriteAPI] addFavorite statusCode: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print(
        '[FavoriteAPI] addFavorite DioException: ${e.type} / status: ${e.response?.statusCode} / data: ${e.response?.data}',
      );
      return false;
    } catch (e) {
      print('[FavoriteAPI] addFavorite 오류: $e');
      return false;
    }
  }

  /// [DELETE /stores/{store_id}/favorite] 즐겨찾기 해제
  Future<bool> removeFavorite(int storeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('[FavoriteAPI] removeFavorite: 토큰 없음');
        return false;
      }

      final response = await _dio.delete(
        ApiConfig.toggleFavorite(storeId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('[FavoriteAPI] removeFavorite statusCode: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print(
        '[FavoriteAPI] removeFavorite DioException: ${e.type} / status: ${e.response?.statusCode} / data: ${e.response?.data}',
      );
      return false;
    } catch (e) {
      print('[FavoriteAPI] removeFavorite 오류: $e');
      return false;
    }
  }

  /// [GET /users/me/favorites] 즐겨찾기 목록 조회
  Future<List<StoreModel>> getFavorites() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        ApiConfig.favorites,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        // 실제 API 응답 구조("data" 필드 내부 배열 여부 등)에 따라 맞게 수정 필요할 수 있습니다.
        List<dynamic> data = [];
        if (response.data is Map && response.data['data'] != null) {
          if (response.data['data'] is Map &&
              response.data['data']['stores'] != null) {
            data = response.data['data']['stores'];
          } else if (response.data['data'] is List) {
            data = response.data['data'];
          }
        } else if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'];
        } else if (response.data is List) {
          data = response.data;
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
            id: json['store_id'] ?? json['id'] ?? 0,
            name: json['store_name'] ?? json['name'] ?? '',
            categories:
                (json['categories'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            rating: parseDouble(json['rating']) ?? 0.0,
            closingTime:
                json['today_close'] ??
                json['closing_time'] ??
                json['closingTime'] ??
                '',
            isFavorite: true,
            imageUrl: json['image_url'] ?? json['imageUrl'],
            latitude: parseDouble(json['store_lat'] ?? json['latitude']),
            longitude: parseDouble(json['store_long'] ?? json['longitude']),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
