import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/auth/data/datasources/auth_api.dart';
import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/app/config/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  // 1. 필요한 변수들 선언
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // <-- 이 줄이 빠져있어서 오류가 났을 겁니다.

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_info';

  // 2. 생성자를 통해 ApiClient의 dio를 AuthRemoteDataSource에 주입
  AuthRepositoryImpl()
      : _remoteDataSource = AuthRemoteDataSource(ApiClient().dio);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _remoteDataSource.login(request);

    if (response.success && response.data != null) {
      print('✅ [Login Success]');

      // 토큰 및 유저 정보 저장 (_storage 사용 가능)
      await _storage.write(
        key: _accessTokenKey,
        value: response.data!.accessToken,
      );
      await _storage.write(
        key: _refreshTokenKey,
        value: response.data!.refreshToken,
      );
      await _storage.write(
        key: _userKey,
        value: jsonEncode({
          'user_id': response.data!.user.userId,
          'user_name': response.data!.user.userName,
          'user_email': response.data!.user.userEmail,
          'user_type': response.data!.user.userType,
          'user_phone': response.data!.user.userPhone,
        }),
      );
    } else {
      print('❌ [Login Failed] Reason: ${response.message}');
    }
    return response;
  }

  @override
  Future<SignupResponse> signup(SignupRequest request) async {
    final response = await _remoteDataSource.register(request);
    if (response.success) {
      print('✅ [Signup Success] userName: ${response.data?.userName}');
    } else {
      print('❌ [Signup Failed] Reason: ${response.message}');
    }
    return response;
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  @override
  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  @override
  Future<bool> uploadProfileImage(File file) async {
    final token = await getAccessToken();
    if (token == null) return false;
    return await _remoteDataSource.uploadProfileImage(file, token);
  }

  @override
  Future<bool> updateProfile(
      String userName,
      String userEmail,
      String userPhone,
      ) async {
    final token = await getAccessToken();
    if (token == null) return false;

    final success = await _remoteDataSource.updateProfile(
      userName,
      userEmail,
      userPhone,
      token,
    );

    if (success) {
      final user = await getUser();
      if (user != null) {
        await _storage.write(
          key: _userKey,
          value: jsonEncode({
            'user_id': user.userId,
            'user_name': userName,
            'user_email': userEmail,
            'user_phone': userPhone,
            'user_type': user.userType,
          }),
        );
      }
    }
    return success;
  }

  @override
  Future<UserModel?> fetchAndSyncUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;
    try {
      final data = await _remoteDataSource.fetchUserProfile(token);
      final user = UserModel(
        userId: data['user_id'],
        userName: data['user_name'],
        userEmail: data['user_email'],
        userPhone: data['user_phone'] ?? '',
        userType: data['user_type'],
      );

      await _storage.write(
        key: _userKey,
        value: jsonEncode({
          'user_id': user.userId,
          'user_name': user.userName,
          'user_email': user.userEmail,
          'user_phone': user.userPhone,
          'user_type': user.userType,
        }),
      );
      return user;
    } catch (e) {
      return null;
    }
  }
}