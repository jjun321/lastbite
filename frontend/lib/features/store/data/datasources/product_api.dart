import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/store/data/models/product_model.dart';

class ProductApi {
  final Dio _dio;

  ProductApi(this._dio);

  // GET /stores/{store_id}/products/
  Future<List<ProductModel>> getStoreProducts(int storeId) async {
    final response = await _dio.get(ApiConfig.storeProducts(storeId));
    final List<dynamic> products = response.data['data']['products'];
    return products.map((e) => ProductModel.fromJson(e)).toList();
  }
}