import 'dart:io';
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

  /// [POST /auth/login]
  /// 사용자의 이메일과 비밀번호를 서버에 전송하여 로그인 처리를 하고 액세스/리프레시 토큰과 사용자 기본 정보 받아옴
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

  /// [POST /auth/register]
  /// 신규 회원가입을 처리하는 API. 이름, 이메일, 비밀번호, 전화번호 등 전송
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

  /// [POST /users/me/profile-image]
  /// 갤러리나 카메라에서 얻은 이미지 파일을 Multipart/form-data 형식으로 서버에 업로드하여 사용자의 프로필 사진을 갱신
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

      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// [PUT /users/me]
  /// 텍스트로 된 사용자 프로필 정보(이름, 이메일, 전화번호)를 한 번에 통째로 수정
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
  /// 현재 인증된 사용자의 가장 최신 프로필 상세 정보를 서버로부터 직접 가져옴
  /// 앱 재시작이나 계정 관리 진입 시 강제 동기화를 위해 사용
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
