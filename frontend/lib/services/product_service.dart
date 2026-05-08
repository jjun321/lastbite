import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

// 점주 쪽 기능 확인만을 위해 제작된 서비스 페이지 - 추후 소비자와 통합 예정

/// 상품 관련 API 서비스
class ProductService {
  static const _base = kBaseUrl;

  // ── 카테고리 목록 ──
  static Future<List<Map<String, dynamic>>> getCategories() async {
    // 카테고리 API는 명세에 없으나 기존 호환성을 위해 남겨두거나 빈 배열 반환
    try {
      final res = await http.get(
        Uri.parse('$_base/categories/'),
        headers: await AuthService.authHeaders(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data'] as List);
      }
    } catch (_) {}
    return [];
  }

  // ── 상품 목록 조회 ──
  static Future<List<Map<String, dynamic>>> getProducts(int storeId) async {
    final res = await http.get(
      Uri.parse('$_base/owner/stores/$storeId/products/'),
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
    int? categoryId,
    String? categoryName,
    required String productName,
    String? productDesc,
    required int oriPrice,
    required int disPrice,
    required int count,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$_base/owner/stores/$storeId/products/');
    final headers = await AuthService.authHeaders();

    if (imageFile != null) {
      final request = http.MultipartRequest('POST', uri);

      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');
      request.headers.addAll(multipartHeaders);

      if (categoryId != null) request.fields['category_id'] = categoryId.toString();
      if (categoryName != null) request.fields['category_name'] = categoryName;
      request.fields['product_name'] = productName;
      request.fields['product_desc'] = productDesc ?? '';
      request.fields['product_ori_price'] = oriPrice.toString();
      request.fields['product_dis_price'] = disPrice.toString();
      request.fields['product_count'] = count.toString();

      request.files.add(
        await http.MultipartFile.fromPath('image_file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          if (categoryId != null) 'category_id': categoryId,
          if (categoryName != null) 'category_name': categoryName,
          'product_name': productName,
          'product_desc': productDesc ?? '',
          'product_ori_price': oriPrice,
          'product_dis_price': disPrice,
          'product_count': count,
        }),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int storeId,
    required int productId,
    int? categoryId,
    String? categoryName,
    String? productName,
    String? productDesc,
    int? oriPrice,
    int? disPrice,
    int? count,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$_base/owner/stores/$storeId/products/$productId/');
    final headers = await AuthService.authHeaders();

    if (imageFile != null) {
      final request = http.MultipartRequest('PATCH', uri);

      final multipartHeaders = Map<String, String>.from(headers);
      multipartHeaders.remove('Content-Type');
      request.headers.addAll(multipartHeaders);

      if (categoryId != null)
        request.fields['category_id'] = categoryId.toString();
      if (categoryName != null) request.fields['category_name'] = categoryName;
      if (productName != null) request.fields['product_name'] = productName;
      if (productDesc != null) request.fields['product_desc'] = productDesc;
      if (oriPrice != null)
        request.fields['product_ori_price'] = oriPrice.toString();
      if (disPrice != null)
        request.fields['product_dis_price'] = disPrice.toString();
      if (count != null) request.fields['product_count'] = count.toString();

      request.files.add(
        await http.MultipartFile.fromPath('image_file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = <String, dynamic>{
        if (categoryId != null) 'category_id': categoryId,
        if (categoryName != null) 'category_name': categoryName,
        if (productName != null) 'product_name': productName,
        if (productDesc != null) 'product_desc': productDesc,
        if (oriPrice != null) 'product_ori_price': oriPrice,
        if (disPrice != null) 'product_dis_price': disPrice,
        if (count != null) 'product_count': count,
      };

      final res = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
  }

  // ── 상품 삭제 (soft delete) ──
  static Future<Map<String, dynamic>> deleteProduct({
    required int storeId,
    required int productId,
  }) async {
    final res = await http.delete(
      Uri.parse('$_base/owner/stores/$storeId/products/$productId/'),
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
      Uri.parse('$_base/owner/stores/$storeId/products/$productId/soldout/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 주문 조회 (S01) ──
  static Future<List<Map<String, dynamic>>> getOrders(int storeId) async {
    final res = await http.get(
      Uri.parse('$_base/owner/stores/$storeId/orders/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data'] as List);
    }
    return [];
  }

  // ── 주문 내역 (S02/S03/S04) ──
  static Future<List<Map<String, dynamic>>> getOrdersHistory(
    int storeId,
  ) async {
    final res = await http.get(
      Uri.parse('$_base/owner/stores/$storeId/orders/history/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data'] as List);
    }
    return [];
  }

  // ── 주문 상세 ──
  static Future<Map<String, dynamic>?> getOrderDetail({
    required int storeId,
    required int orderId,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/owner/stores/$storeId/orders/$orderId/'),
      headers: await AuthService.authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ── 주문 수락 (S01->S02) ──
  static Future<Map<String, dynamic>> acceptOrder({
    required int storeId,
    required int orderId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/owner/stores/$storeId/orders/$orderId/accept/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 주문 취소 (S01->S04) ──
  static Future<Map<String, dynamic>> cancelOrder({
    required int storeId,
    required int orderId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/owner/stores/$storeId/orders/$orderId/cancel/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── 픽업 완료 (S02->S03) ──
  static Future<Map<String, dynamic>> completeOrder({
    required int storeId,
    required int orderId,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/owner/stores/$storeId/orders/$orderId/complete/'),
      headers: await AuthService.authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
