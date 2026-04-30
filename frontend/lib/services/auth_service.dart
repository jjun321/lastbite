import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 점주 쪽 기능 구현 확인만을 위해 제작된 서비스 페이지 - 추후 소비자와 통합 예정
// API 기본 URL — 실기기 테스트 시 실제 서버 IP로 교체

const String kBaseUrl =
    'https://joya-nonstrategical-supersmartly.ngrok-free.dev'; // Android 에뮬레이터 localhost

/// 공통 서비스 클래스 — 토큰 저장/로드, 인증 헤더 생성
class AuthService {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserType = 'user_type';

  // ── 토큰 저장 ──
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, accessToken);
    await prefs.setString(_keyRefresh, refreshToken);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserType, userType);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_keyAccess);
    if (token != null) return token;

    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'access_token');
    return token;
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    String? type = prefs.getString(_keyUserType);
    if (type != null) return type;

    const storage = FlutterSecureStorage();
    final userJson = await storage.read(key: 'user_info');
    if (userJson != null) {
      try {
        final Map<String, dynamic> user = jsonDecode(userJson);
        return user['user_type'];
      } catch (_) {}
    }
    return null;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  // ── 인증 헤더 ──
  static Future<Map<String, String>> authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── 로그인 ──
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_email': email, 'user_password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      final data = body['data'] as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        userId: data['user']['user_id'],
        userType: data['user']['user_type'],
      );
    }
    return body;
  }

  // ── 내 프로필 조회 ──
  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/users/me'),
      headers: await authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 내 프로필 수정 ──
  static Future<Map<String, dynamic>> updateMyProfile({
    String? userName,
    String? userEmail,
    String? userPhone,
  }) async {
    final body = <String, dynamic>{};
    if (userName != null) body['user_name'] = userName;
    if (userEmail != null) body['user_email'] = userEmail;
    if (userPhone != null) body['user_phone'] = userPhone;

    final res = await http.put(
      Uri.parse('$kBaseUrl/users/me'),
      headers: await authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 프로필 이미지 업로드 ──
  // POST /users/me/profile-image — multipart/form-data, 필드명 'image_file'
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final uri = Uri.parse('$kBaseUrl/users/me/profile-image');
    final request = http.MultipartRequest('POST', uri);

    final headers = await authHeaders();
    headers.remove('Content-Type'); // multipart 경계자 자동 설정 위해 제거
    request.headers.addAll(headers);

    request.files.add(
      await http.MultipartFile.fromPath('image_file', imageFile.path),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
