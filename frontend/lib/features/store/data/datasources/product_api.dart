import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/store/data/models/product_model.dart';

class ProductApi {
  final Dio _dio;

  ProductApi(this._dio);

  // GET /stores/{store_id}/products/?sort=&category_id=
  Future<List<ProductModel>> getStoreProducts(
    int storeId, {
    String? sort,
    int? categoryId,
  }) async {
    final response = await _dio.get(
      ApiConfig.storeProducts(storeId),
      queryParameters: {
        if (sort != null) 'sort': sort,
        if (categoryId != null) 'category_id': categoryId,
      },
    );
    final List<dynamic> products = response.data['data']['products'];
    return products.map((e) => ProductModel.fromJson(e)).toList();
  }

  // GET /products/hotdeal/
  Future<List<ProductModel>> getHotDealProducts({
    double? lat,
    double? lon,
    int? radius,
    int? size,
  }) async {
    final response = await _dio.get(
      ApiConfig.hotdeal,
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (radius != null) 'radius': radius,
        if (size != null) 'size': size,
      },
    );
    final List<dynamic> products = response.data['data']['products'];
    return products.map((e) => ProductModel.fromJson(e)).toList();
  }
}