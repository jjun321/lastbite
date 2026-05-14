class StoreModel {
  final int storeId;
  final String storeName;
  final String storeAddress;
  final double? storeLat;
  final double? storeLon;
  final bool isClosed;
  final bool isOffToday;
  final bool isFavorite;
  final bool isAiRecommended;
  final String? todayOpen;
  final String? todayClose;
  final double? distanceKm;
  final String? repProductName;
  final int? repProductDisPrice;
  final int? repProductDiscountRate;
  final String? storeImgUrl;

  StoreModel({
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    this.storeLat,
    this.storeLon,
    required this.isClosed,
    required this.isOffToday,
    this.isFavorite = false,
    this.isAiRecommended = false,
    this.todayOpen,
    this.todayClose,
    this.distanceKm,
    this.repProductName,
    this.repProductDisPrice,
    this.repProductDiscountRate,
    this.storeImgUrl,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final repProduct = json['rep_product'];
    return StoreModel(
      storeId: json['store_id'],
      storeName: json['store_name'],
      storeAddress: json['store_address'],
      storeLat: json['store_lat'] != null
          ? double.parse(json['store_lat'].toString())
          : null,
      storeLon: json['store_long'] != null
          ? double.parse(json['store_long'].toString())
          : null,
      isClosed: json['is_closed'] ?? false,
      isOffToday: json['is_off_today'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      isAiRecommended: json['is_ai_recommended'] ?? false,
      todayOpen: json['today_open'],
      todayClose: json['today_close'],
      distanceKm: json['distance_km'] != null
          ? double.parse(json['distance_km'].toString())
          : null,
      repProductName: repProduct?['product_name'],
      repProductDisPrice: repProduct?['dis_price'],
      repProductDiscountRate: repProduct?['discount_rate'],
      storeImgUrl: json['store_img_url'] as String?,
    );
  }

  StoreModel copyWith({bool? isFavorite, bool? isAiRecommended}) {
    return StoreModel(
      storeId: storeId,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLat: storeLat,
      storeLon: storeLon,
      isClosed: isClosed,
      isOffToday: isOffToday,
      isFavorite: isFavorite ?? this.isFavorite,
      isAiRecommended: isAiRecommended ?? this.isAiRecommended,
      todayOpen: todayOpen,
      todayClose: todayClose,
      distanceKm: distanceKm,
      repProductName: repProductName,
      repProductDisPrice: repProductDisPrice,
      repProductDiscountRate: repProductDiscountRate,
      storeImgUrl: storeImgUrl,
    );
  }
}
