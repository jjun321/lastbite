// 임시 데이터!! 데베 연결 후 삭제 예정

import '../data/models.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/features/store/data/models/store_model.dart';



// 제보 게시판 더미 데이터 추가
final List<CommunityReport> reportList = [
  CommunityReport(
    date: "2026.01.01.",
    title: "할인",
    storeName: "소금빵 가게",
    content: "지금 소금빵 3,000원에 마감 할인 중이에요! 서두르세요.",
  ),
  CommunityReport(
    date: "2026.01.02.",
    title: "할인",
    storeName: "한성 베이커리",
    content: "오늘 크루아상은 품절이라고 합니다. 참고하세요!",
  ),
  CommunityReport(
    date: "2026.01.03.",
    title: "할인",
    storeName: "도너츠 랜드",
    content: "오늘 하루 1+1 이벤트 진행 중입니다.",
  ),
];


// 1. 가게 정보
final StoreModel myStore = StoreModel(
  storeId: 1,
  storeName: "소금빵 가게",
  storeAddress: "서울특별시 성북구 00동 000 1층 000호",
  todayClose: "20:00",
  isClosed: false,
  isOffToday: false,
);

// 사용자 정보
final UserInfo currentUser = UserInfo(
  name: "김한성",
  phoneNumber: "010-1234-5678",
  totalSavings: "1,250,000",
);

// 2. 메뉴 목록 (기본 DB)
final List<ProductModel> menuList = [
  ProductModel(productId: 1, productName: "소금빵", productOriPrice: 10000, productDisPrice: 3000, discountRate: 70, isAvailable: true),
  ProductModel(productId: 2, productName: "크루아상", productOriPrice: 5000, productDisPrice: 2000, discountRate: 60, isAvailable: true),
  ProductModel(productId: 3, productName: "단팥빵", productOriPrice: 3000, productDisPrice: 1500, discountRate: 50, isAvailable: true),
  ProductModel(productId: 4, productName: "바게트", productOriPrice: 4000, productDisPrice: 800, discountRate: 80, isAvailable: true),
  ProductModel(productId: 5, productName: "메론빵", productOriPrice: 4000, productDisPrice: 2000, discountRate: 50, isAvailable: true),
  ProductModel(productId: 6, productName: "식빵", productOriPrice: 6000, productDisPrice: 4200, discountRate: 30, isAvailable: true),
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