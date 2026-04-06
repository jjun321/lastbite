import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/auth/data/datasources/auth_api.dart';
import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

// AuthRepository 인터페이스의 실제 구현체
// 백엔드 통신(Remote)과 기기내 로컬 저장소(SecureStorage)를 모두 제어하여 로그인, 로그아웃, 회원가입 등을 수행하는 부분
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource = AuthRemoteDataSource();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_info';

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _remoteDataSource.login(request);

    if (response.success && response.data != null) {
      // 콘솔 출력: 로그인 성공
      print('✅ [Login Success]');
      print('   - User Name: ${response.data!.user.userName}');
      print('   - User Type: ${response.data!.user.userType}');
      print(
        '   - Access Token: ${response.data!.accessToken.substring(0, 10)}...',
      );

      // 토큰 및 유저 정보 저장
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
        }),
      );
    } else {
      // 콘솔 출력: 로그인 실패
      print('❌ [Login Failed]');
      print('   - Reason: ${response.message}');
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
}
