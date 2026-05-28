import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/features/consumer/board/data/post_model.dart';

/// 제보(Post) 관련 API 서비스
class PostService {
  static String get _base => kBaseUrl;

  // ── 제보 목록 조회 ──
  // lat, long: 현재 위치 (nullable)
  // radiusKm: 검색 반경 (기본 3km)
  static Future<List<PostModel>> fetchPosts({
    double? lat,
    double? long,
    int radiusKm = 3,
    int page = 0,
    int size = 20,
    String? sort,       // 'latest' (기본) / 'ordered' (주문한 상품 관련)
    int? productId,     // 특정 상품 관련 포스트만
    int? storeId,       // 특정 매장 포스트만
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      'radius': '$radiusKm',
      if (lat != null) 'lat': '$lat',
      if (long != null) 'long': '$long',
      if (sort != null) 'sort': sort,
      if (productId != null) 'product_id': '$productId',
      if (storeId != null) 'store_id': '$storeId',
    };

    final uri = Uri.parse('$_base/posts/').replace(queryParameters: params);
    try {
      final res = await http.get(uri, headers: await AuthService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final posts = (body['data']['posts'] as List<dynamic>)
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return posts;
      }
    } catch (e) {
      debugPrint('fetchPosts error: $e');
    }
    return [];
  }

  // ── 제보 작성 (이미지 포함 multipart) ──
  static Future<bool> createPost({
    required String postName,
    String? content,
    int? storeId,
    double? postLat,
    double? postLong,
    File? imageFile,
    int? productId,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final request = http.MultipartRequest('POST', Uri.parse('$_base/posts/'))
        ..headers.addAll(headers);

      request.fields['post_name'] = postName;
      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }
      if (storeId != null) {
        request.fields['store_id'] = '$storeId';
      }
      if (postLat != null) {
        request.fields['post_lat'] = '$postLat';
      }
      if (postLong != null) {
        request.fields['post_long'] = '$postLong';
      }
      if (productId != null) {
        request.fields['product_id'] = '$productId';
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image_file', imageFile.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      debugPrint('createPost error: $e');
      return false;
    }
  }

  // ── 매장 검색 (이름 기반: 전체 조회 후 클라이언트 필터) ──
  static Future<List<Map<String, dynamic>>> searchStores(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      // 좌표 없이 전체 매장 조회, 이름으로 클라이언트 필터링
      final uri = Uri.parse('$_base/stores/').replace(
        queryParameters: {
          'radius': '3000', // 최대 반경으로 전체 조회
          'size': '50',
        },
      );
      final res = await http.get(uri, headers: await AuthService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final stores = body['data']['stores'] as List<dynamic>;
        final lowerQuery = query.toLowerCase();
        return stores
            .where((s) {
              final name = (s['store_name'] as String? ?? '').toLowerCase();
              return name.contains(lowerQuery);
            })
            .map((s) => s as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      debugPrint('searchStores error: $e');
    }
    return [];
  }
}
