class OrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final int productDisPrice;
  final int productOriPrice;
  final int subtotal;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.productDisPrice,
    required this.productOriPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      // ?? 를 사용하여 null이 올 경우 기본값을 할당합니다.
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      productDisPrice: json['product_dis_price'] ?? 0,
      productOriPrice: json['product_ori_price'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final int orderId;
  final int storeId;
  final String storeName;
  final String orderStatus;
  final DateTime pickupDt;
  final DateTime orderDt;
  final List<OrderItemModel> items;
  final int totalPrice;

  OrderModel({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.orderStatus,
    required this.pickupDt,
    required this.orderDt,
    required this.items,
    required this.totalPrice,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      // 모든 필드에 방어적 코드를 추가합니다.
      orderId: json['order_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      storeName: json['store_name'] ?? '알 수 없는 가게',
      orderStatus: json['order_status'] ?? 'S01',
      // 날짜 데이터가 null로 올 경우를 대비해 현재 시간으로 방어 처리
      pickupDt: json['pickup_dt'] != null
          ? DateTime.parse(json['pickup_dt'])
          : DateTime.now(),
      orderDt: json['order_dt'] != null
          ? DateTime.parse(json['order_dt'])
          : DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
      totalPrice: json['total_price'] ?? 0,
    );
  }
}