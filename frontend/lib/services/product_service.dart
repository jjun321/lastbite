import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

// 점주 쪽 기능 확인만을 위해 제작된 서비스 페이지 - 추후 소비자와 통합 예정

/// 상품 관련 API 서비스
class ProductService {
  static const _base = kBaseUrl;

  // ── 카테고리 목록 ──
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await http.get(
      Uri.parse('$_base/categories/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data'] as List);
    }
    return [];
  }

  // ── 상품 목록 조회 ──
  static Future<List<Map<String, dynamic>>> getProducts(int storeId) async {
    final res = await http.get(
      Uri.parse('$_base/stores/$storeId/products/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      final data = body['data'] as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['products'] as List);
    }
    return [];
  }

  // ── 상품 등록 ──
  static Future<Map<String, dynamic>> createProduct({
    required int storeId,
    required int categoryId,
    required String productName,
    String? productDesc,
    required int oriPrice,
    required int disPrice,
    required int count,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/stores/$storeId/products/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({
        'category_id': categoryId,
        'product_name': productName,
        'product_desc': productDesc ?? '',
        'product_ori_price': oriPrice,
        'product_dis_price': disPrice,
        'product_count': count,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 상품 수정 ──
  static Future<Map<String, dynamic>> updateProduct({
    required int storeId,
    required int productId,
    int? categoryId,
    String? productName,
    String? productDesc,
    int? oriPrice,
    int? disPrice,
    int? count,
  }) async {
    final body = <String, dynamic>{
      if (categoryId != null) 'category_id': categoryId,
      if (productName != null) 'product_name': productName,
      if (productDesc != null) 'product_desc': productDesc,
      if (oriPrice != null) 'product_ori_price': oriPrice,
      if (disPrice != null) 'product_dis_price': disPrice,
      if (count != null) 'product_count': count,
    };
    final res = await http.put(
      Uri.parse('$_base/stores/$storeId/products/$productId/'),
      headers: await AuthService.authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 상품 삭제 (soft delete) ──
  static Future<Map<String, dynamic>> deleteProduct({
    required int storeId,
    required int productId,
  }) async {
    final res = await http.delete(
      Uri.parse('$_base/stores/$storeId/products/$productId/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 품절 처리 ──
  static Future<Map<String, dynamic>> setSoldOut({
    required int storeId,
    required int productId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/stores/$storeId/products/$productId/soldout/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
