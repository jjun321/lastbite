import 'package:dio/dio.dart';
import 'package:frontend/app/config/api_config.dart';
import 'package:frontend/features/store/data/models/store_model.dart';

class StoreApi {
  final Dio _dio;

  StoreApi(this._dio);

  // GET /stores/{store_id}/
  Future<StoreModel> getStoreDetail(int storeId) async {
    final response = await _dio.get(ApiConfig.storeDetail(storeId));
    return StoreModel.fromJson(response.data['data']);
  }

  // GET /stores/ (위치 기반 목록)
  Future<List<StoreModel>> getStores({
    double? lat,
    double? lon,
    int radius = 3,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiConfig.stores,
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        'radius': radius,
        'page': page,
        'size': size,
      },
    );
    final List<dynamic> stores = response.data['data']['stores'];
    return stores.map((e) => StoreModel.fromJson(e)).toList();
  }
}