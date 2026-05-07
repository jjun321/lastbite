/// 주문 내역 상세의 개별 상품 모델
class OwnerOrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final int subtotal;
  final int productDisPrice;
  final int productOriPrice;

  OwnerOrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.subtotal,
    required this.productDisPrice,
    required this.productOriPrice,
  });

  factory OwnerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return OwnerOrderItemModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      productDisPrice: json['product_dis_price'] ?? 0,
      productOriPrice: json['product_ori_price'] ?? 0,
    );
  }
}

/// 주문 전체 정보 모델
class OwnerOrderModel {
  final int orderId;
  final String orderStatus;
  final String buyerName;
  final String itemSummary;
  final int totalPrice; // List(total_price)와 Detail(total_dis_price) 호환
  final String pickupDt;
  final String orderDt;

  // 상세 조회를 위한 추가 필드
  final List<OwnerOrderItemModel>? items;
  final int totalOriPrice;
  final int totalDiscount;
  final Map<String, dynamic>? buyer;

  OwnerOrderModel({
    required this.orderId,
    required this.orderStatus,
    required this.buyerName,
    required this.itemSummary,
    required this.totalPrice,
    required this.pickupDt,
    required this.orderDt,
    this.items,
    this.totalOriPrice = 0,
    this.totalDiscount = 0,
    this.buyer,
  });

  factory OwnerOrderModel.fromJson(Map<String, dynamic> json) {
    return OwnerOrderModel(
      orderId: json['order_id'] ?? 0,
      orderStatus: json['order_status'] ?? '',

      // 1. 주문자명: 상세(buyer 객체) 혹은 목록(buyer_name 문자열) 대응
      buyerName: json['buyer_name'] ?? (json['buyer']?['user_name'] ?? '이름 없음'),

      itemSummary: json['item_summary'] ?? '',

      // 2. 가격: 상세(total_dis_price) 혹은 목록(total_price) 대응
      totalPrice: json['total_dis_price'] ?? json['total_price'] ?? 0,

      pickupDt: json['pickup_dt'] ?? '',
      orderDt: json['order_dt'] ?? '',

      // 3. 상세 전용 필드들
      totalOriPrice: json['total_ori_price'] ?? 0,
      totalDiscount: json['total_discount'] ?? 0,
      buyer: json['buyer'],

      // 4. 상품 리스트 매핑 (List<dynamic> -> List<OwnerOrderItemModel>)
      items: json['items'] != null
          ? (json['items'] as List)
          .map((i) => OwnerOrderItemModel.fromJson(i))
          .toList()
          : null,
    );
  }
}