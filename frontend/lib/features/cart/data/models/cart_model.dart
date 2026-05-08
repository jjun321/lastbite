import 'package:frontend/app/config/api_config.dart';

class CartItemModel {
  final String cartItemId;
  final int productId;
  final String productName;
  final int productDisPrice; // 할인가
  final int productOriPrice; // 정가
  final int quantity;
  final int productQty;
  final int subtotal; // 할인가 * 수량
  final String? imgUrl;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productDisPrice,
    required this.productOriPrice,
    required this.quantity,
    required this.productQty,
    required this.subtotal,
    this.imgUrl,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // 백엔드 키값(product_dis_price, product_ori_price) 매핑
    final disPrice = json['product_dis_price'] ?? 0;
    final oriPrice = json['product_ori_price'] ?? disPrice;

    return CartItemModel(
      cartItemId: (json['cart_item_id'] ?? '').toString(),
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '상품명 없음',
      productDisPrice: disPrice,
      productOriPrice: oriPrice,
      quantity: json['quantity'] ?? 0,
      productQty: json['product_qty'] ?? 0,
      subtotal: json['subtotal'] ?? (disPrice * (json['quantity'] ?? 0)), // subtotal이 없으면 계산
      imgUrl: ApiConfig.getImageUrl(json['img_url']),
    );
  }

  // copyWith 수정: 수량이 변경될 때 subtotal도 자동으로 계산되도록 로직 보강
  CartItemModel copyWith({
    int? quantity,
    int? subtotal,
    String? imgUrl,
  }) {
    final newQuantity = quantity ?? this.quantity;
    return CartItemModel(
      cartItemId: cartItemId,
      productId: productId,
      productName: productName,
      productDisPrice: productDisPrice,
      productOriPrice: productOriPrice,
      quantity: newQuantity,
      productQty: productQty,
      // 수량은 변했는데 subtotal이 새로 안 들어오면, 할인가 기준으로 다시 계산
      subtotal: subtotal ?? (productDisPrice * newQuantity),
      imgUrl: imgUrl ?? this.imgUrl,
    );
  }
}

class CartModel {
  final int storeId;
  final String storeName;
  final List<CartItemModel> items;
  final int totalQuantity;
  final int totalPrice;

  CartModel({
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.totalQuantity,
    required this.totalPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      storeId: json['store_id'] ?? 0,
      storeName: json['store_name'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => CartItemModel.fromJson(e))
          .toList() ?? [],
      totalQuantity: json['total_quantity'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
    );
  }
}