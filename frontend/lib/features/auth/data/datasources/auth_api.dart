import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';

class AuthRemoteDataSource {
  // 외부에서 주입받은 Dio 인스턴스 사용
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// [POST /auth/login]
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// [POST /auth/register]
  Future<SignupResponse> register(SignupRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: request.toJson(),
      );
      return SignupResponse.fromJson(response.data);
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// [POST /users/me/profile-image]
  Future<bool> uploadProfileImage(File file, String token) async {
    try {
      final fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image_file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConfig.usersMeProfileImage,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  /// [PUT /users/me]
  Future<bool> updateProfile(
      String userName,
      String userEmail,
      String userPhone,
      String token,
      ) async {
    try {
      final response = await _dio.put(
        ApiConfig.usersMe,
        data: {
          'user_name': userName,
          'user_email': userEmail,
          'user_phone': userPhone,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// [GET /users/me]
  Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    try {
      final response = await _dio.get(
        ApiConfig.usersMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Failed to fetch user profile');
    } catch (e) {
      rethrow;
    }
  }
}