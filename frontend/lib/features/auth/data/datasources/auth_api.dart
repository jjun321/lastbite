import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';

// Dio 패키지를 사용하여 백엔드 인증 관련 API와 실제로 통신하고 JSON 데이터를 가져오는 클래스
class AuthRemoteDataSource {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      // 에러 처리 로직
      rethrow;
    }
  }

  Future<SignupResponse> register(SignupRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return SignupResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      // 400 Bad Request 등 에러 처리 로직
      // 백엔드는 400에서 JSON으로 error_msg를 넘겨주지만(명세서 "message" 필드로),
      // 일단 DioException을 그대로 던지고 Repository에서 처리하도록 합니다.
      rethrow;
    }
  }
}
