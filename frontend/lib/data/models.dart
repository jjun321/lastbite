// 임시 데이터!! 데베 연결 후 삭제 예정

import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/features/store/data/models/store_model.dart';

class CommunityReport {
  final String date;
  final String title;
  final String storeName;
  final String content;

  CommunityReport({
    required this.date,
    required this.title,
    required this.storeName,
    required this.content,
  });
}


class UserInfo {
  final String name;
  final String phoneNumber;
  final String? totalSavings;

  UserInfo({required this.name, required this.phoneNumber, this.totalSavings});
}


class CartItem {
  final ProductModel menu;
  int quantity;

  CartItem({required this.menu, this.quantity = 1});

  int get totalPrice => (menu.productDisPrice ?? 0) * quantity;
}

class Order {
  final String orderNo;
  final List<CartItem> items;
  final String price; // 기존 수동 입력 필드
  final String pickupTime;
  bool isCancelled;
  bool isAccepted;

  Order({
    required this.orderNo,
    required this.items,
    required this.price,
    required this.pickupTime,
    this.isCancelled = false,
    this.isAccepted = false,
  });

  // 1. 전체 정가 계산 (할인 전)
  int get totalOriginalPrice {
    return items.fold(0, (sum, item) => sum + ((item.menu.productOriPrice ?? 0) * item.quantity));
  }

  // 2. 최종 합계 계산 (실제 계산된 할인가 합계)
  int get totalCalculatedPrice {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // 3. 전체 할인액 계산 (정가 - 합계)
  int get totalDiscountAmount {
    return totalOriginalPrice - totalCalculatedPrice;
  }

  // 4. 숫자 포맷팅 함수
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // 5. 화면 표시용 (중복 제거 완료)
  String get formattedOriginalPrice => "${_formatNumber(totalOriginalPrice)} 원";
  String get formattedDiscountAmount => "${_formatNumber(totalDiscountAmount)} 원";
  String get formattedTotalPrice => "${_formatNumber(totalCalculatedPrice)} 원";

  String get representativeName {
    if (items.isEmpty) return "주문 상품 없음";
    if (items.length == 1) return items[0].menu.productName;
    return "${items[0].menu.productName} 외 ${items.length - 1}건";
  }

  String get totalCountString {
    int totalCount = items.fold(0, (sum, item) => sum + item.quantity);
    return "$totalCount개";
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNo: json['order_no'] ?? '',
      items: [],
      price: json['price'] ?? '',
      pickupTime: json['pickup_time'] ?? '',
      isCancelled: json['is_cancelled'] ?? false,
      isAccepted: json['is_accepted'] ?? false,
    );
  }
}

class StoreStats {
  final String storeName;
  final String totalSales;
  final List<String> bestSellers;
  final List<String> worstSellers;

  StoreStats({
    required this.storeName,
    required this.totalSales,
    required this.bestSellers,
    required this.worstSellers,
  });
}