import 'package:frontend/app/config/api_config.dart';

class CartItemModel {
  final String cartItemId;
  final int productId;
  final String productName;
  final int productDisPrice; // 할인가
  final int productOriPrice; // ✅ 정가 추가
  final int quantity;
  final int productQty;
  final int subtotal;
  final String? imgUrl;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productDisPrice,
    required this.productOriPrice, // ✅ 추가
    required this.quantity,
    required this.productQty,
    required this.subtotal,
    this.imgUrl,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // 백엔드에서 정가(product_ori_price)를 안 보내줄 경우 할인가를 기본값으로 사용
    final disPrice = json['product_dis_price'] ?? 0;
    final oriPrice = json['product_ori_price'] ?? disPrice;

    return CartItemModel(
      cartItemId: (json['cart_item_id'] ?? '').toString(),
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '상품명 없음',
      productDisPrice: disPrice,
      productOriPrice: oriPrice, // ✅ 할인가 또는 정가 매핑
      quantity: json['quantity'] ?? 0,
      productQty: json['product_qty'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      imgUrl: ApiConfig.getImageUrl(json['img_url']),
    );
  }

  CartItemModel copyWith({int? quantity, int? subtotal, String? imgUrl}) {
    return CartItemModel(
      cartItemId: cartItemId,
      productId: productId,
      productName: productName,
      productDisPrice: productDisPrice,
      productOriPrice: productOriPrice,
      quantity: quantity ?? this.quantity,
      productQty: productQty,
      subtotal: subtotal ?? this.subtotal,
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