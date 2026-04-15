import 'package:frontend/features/store/data/datasources/store_api.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/app/config/api_client.dart';

class StoreRepositoryImpl {
  final StoreApi _api;

  StoreRepositoryImpl() : _api = StoreApi(ApiClient().dio);

  Future<StoreModel> getStoreDetail(int storeId) async {
    try {
      return await _api.getStoreDetail(storeId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StoreModel>> getStores({
    double? lat,
    double? lon,
    int radius = 3,
  }) async {
    try {
      return await _api.getStores(lat: lat, lon: lon, radius: radius);
    } catch (e) {
      rethrow;
    }
  }
}