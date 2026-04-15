class CartItemModel {
  final String cartItemId;
  final int productId;
  final String productName;
  final int productDisPrice;
  final int quantity;
  final int productQty;
  final int subtotal;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productDisPrice,
    required this.quantity,
    required this.productQty,
    required this.subtotal,
  });

  // features/cart/data/models/cart_model.dart 내 수정
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      // .toString()을 붙여서 서버가 int를 주든 String을 주든 무조건 문자로 만듭니다.
      cartItemId: (json['cart_item_id'] ?? '').toString(),
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '상품명 없음',
      productDisPrice: json['product_dis_price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      productQty: json['product_qty'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
    );
  }

  CartItemModel copyWith({int? quantity, int? subtotal}) {
    return CartItemModel(
      cartItemId: cartItemId,
      productId: productId,
      productName: productName,
      productDisPrice: productDisPrice,
      quantity: quantity ?? this.quantity,
      productQty: productQty,
      subtotal: subtotal ?? this.subtotal,
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