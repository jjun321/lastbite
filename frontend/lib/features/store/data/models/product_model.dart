import 'package:frontend/app/config/api_config.dart'; // ✅ 임포트 필수

class ProductModel {
  final int productId;
  final int? categoryId;
  final String? categoryName;
  final String productName;
  final String? productDesc;
  final int? productOriPrice;
  final int? productDisPrice;
  final int discountRate;
  final int? productCount;
  final String? imgUrl;
  final bool isAvailable;

  // 검색/핫딜 API 전용 필드
  final int? storeId;
  final String? storeName;
  final String? storeAddress;
  final double? distanceKm;
  final double? storeLat;
  final double? storeLon;
  final bool isSpecial;     // ML 이상치 탐지 HIGH — "특가" 배지
  final bool isPreferred;   // 유저가 주문한 카테고리 소속 — 상단 고정

  ProductModel({
    required this.productId,
    this.categoryId,
    this.categoryName,
    required this.productName,
    this.productDesc,
    this.productOriPrice,
    this.productDisPrice,
    required this.discountRate,
    this.productCount,
    this.imgUrl,
    required this.isAvailable,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.distanceKm,
    this.storeLat,
    this.storeLon,
    this.isSpecial = false,
    this.isPreferred = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      productName: json['product_name'] ?? '상품명 없음',
      productDesc: json['product_desc'],
      productOriPrice: json['product_ori_price'],
      productDisPrice: json['product_dis_price'],
      discountRate: json['discount_rate'] ?? 0,
      productCount: json['product_count'],

      // ✅ 가장 중요한 수정: 상대 경로를 전체 URL로 변환
      imgUrl: ApiConfig.getImageUrl(json['img_url']),

      isAvailable: json['is_available'] ?? false,

      // 검색/핫딜 API 전용 필드
      storeId: json['store_id'],
      storeName: json['store_name'],
      storeAddress: json['store_address'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      storeLat: (json['store_lat'] as num?)?.toDouble(),
      storeLon: (json['store_lon'] as num?)?.toDouble(),
      isSpecial: json['is_special'] ?? false,
      isPreferred: json['is_preferred'] ?? false,
    );
  }
}