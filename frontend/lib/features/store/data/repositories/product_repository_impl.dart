import 'package:frontend/features/store/data/datasources/product_api.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/app/config/api_client.dart';

class ProductRepositoryImpl {
  final ProductApi _api;

  ProductRepositoryImpl() : _api = ProductApi(ApiClient().dio);

  Future<List<ProductModel>> getStoreProducts(int storeId) async {
    try {
      return await _api.getStoreProducts(storeId);
    } catch (e) {
      rethrow;
    }
  }
}