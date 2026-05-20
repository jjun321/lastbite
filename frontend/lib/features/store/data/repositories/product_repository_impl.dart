import 'package:frontend/features/store/data/datasources/product_api.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/app/config/api_client.dart';

class ProductRepositoryImpl {
  final ProductApi _api;

  ProductRepositoryImpl() : _api = ProductApi(ApiClient().dio);

  Future<List<ProductModel>> getStoreProducts(
    int storeId, {
    String? sort,
    int? categoryId,
  }) async {
    try {
      return await _api.getStoreProducts(
        storeId,
        sort: sort,
        categoryId: categoryId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getHotDealProducts({
    double? lat,
    double? lon,
    int? radius,
    int? size,
  }) async {
    try {
      return await _api.getHotDealProducts(
        lat: lat,
        lon: lon,
        radius: radius,
        size: size,
      );
    } catch (e) {
      rethrow;
    }
  }
}