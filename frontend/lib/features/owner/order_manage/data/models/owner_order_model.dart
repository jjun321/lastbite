class OwnerOrderModel {
  final int orderId;
  final String orderStatus;
  final String buyerName;
  final String itemSummary;
  final int totalPrice;
  final String pickupDt;
  final String orderDt;
  // 상세 내역을 위한 items 필드 추가
  final List<OwnerOrderItemModel>? items;

  OwnerOrderModel({
    required this.orderId,
    required this.orderStatus,
    required this.buyerName,
    required this.itemSummary,
    required this.totalPrice,
    required this.pickupDt,
    required this.orderDt,
    this.items,
  });

  factory OwnerOrderModel.fromJson(Map<String, dynamic> json) {
    return OwnerOrderModel(
      orderId: json['order_id'] ?? 0,
      orderStatus: json['order_status'] ?? '',
      buyerName: json['buyer_name'] ?? '',
      itemSummary: json['item_summary'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      pickupDt: json['pickup_dt'] ?? '',
      orderDt: json['order_dt'] ?? '',
      // items가 json에 있을 경우 파싱
      items: json['items'] != null
          ? (json['items'] as List)
          .map((i) => OwnerOrderItemModel.fromJson(i))
          .toList()
          : null,
    );
  }
}

// 개별 상품 정보를 담는 클래스 추가
class OwnerOrderItemModel {
  final String productName;
  final int quantity;
  final int subtotal;

  OwnerOrderItemModel({
    required this.productName,
    required this.quantity,
    required this.subtotal,
  });

  factory OwnerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return OwnerOrderItemModel(
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
    );
  }
}