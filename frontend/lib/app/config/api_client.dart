import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // 1. 싱글톤 설정
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    // 2. 인터셉터 추가:
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); // 다음 단계로 진행
      },
    ));
  }
}