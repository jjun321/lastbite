// 임시 데이터!! 데베 연결 후 삭제 예정

import '../data/models.dart';

// 1. 가게 정보
final StoreInfo myStore = StoreInfo(
  name: "소금빵 가게",
  description: "매일 아침 직접 굽는 신선한 빵 소금빵 가게 어쩌구 이어서 가게 소개 작성",
  address: "서울특별시 성북구 00동 000 1층 000호",
  closingTime: "20:00",
);

// 사용자 정보
final UserInfo currentUser = UserInfo(
  name: "김한성",
  phoneNumber: "010-1234-5678",
  totalSavings: "1,250,000",
);

// 2. 메뉴 목록 (기본 DB)
final List<MenuItem> menuList = [
  MenuItem(name: "소금빵", originalPrice: 10000, discountedPrice: 3000), // 70% 할인
  MenuItem(name: "크루아상", originalPrice: 5000, discountedPrice: 2000), // 60% 할인
  MenuItem(name: "단팥빵", originalPrice: 3000, discountedPrice: 1500), // 50% 할인
  MenuItem(name: "바게트", originalPrice: 4000, discountedPrice: 800),  // 80% 할인
  MenuItem(name: "메론빵", originalPrice: 4000, discountedPrice: 2000), // 50% 할인
  MenuItem(name: "식빵", originalPrice: 6000, discountedPrice: 4200), // 30% 할인
];

// 3. 실시간 장바구니
List<CartItem> myCart = [];

// 4. 주문 리스트
List<Order> orderList = [
  Order(
    orderNo: '#162432',
    items: [
      CartItem(menu: menuList[0], quantity: 1), // 소금빵 1개
    ],
    price: "3,000 원",
    pickupTime: "2026.01.01. 07:30~08:00 PM",
    isAccepted: false,
    isCancelled: false,
  ),
  Order(
    orderNo: '#162433',
    items: [
      CartItem(menu: menuList[4], quantity: 2), // 메론빵 2개
      CartItem(menu: menuList[1], quantity: 1), // 크루아상 1개 (여러 메뉴 예시)
    ],
    price: "7,000 원",
    pickupTime: "2026.01.01. 08:00~08:30 PM",
    isAccepted: false,
    isCancelled: false,
  ),
  Order(
    orderNo: '#162430',
    items: [
      CartItem(menu: menuList[5], quantity: 1), // 식빵 1개
    ],
    price: "4,200 원",
    pickupTime: "2026.01.01. 09:00~09:30 PM",
    isAccepted: false,
    isCancelled: true, // 취소된 데이터
  ),
];

// 5. 대시보드용 통계 데이터
final StoreStats myStoreStats = StoreStats(
  storeName: "소금빵 가게",
  totalSales: "1,250,000",
  bestSellers: ["소금빵", "크루아상", "단팥빵"],
  worstSellers: ["식빵", "베이글", "스콘"],
);