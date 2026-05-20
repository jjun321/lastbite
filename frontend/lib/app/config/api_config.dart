// 백엔드 서버의 베이스 URL 및 각 엔드포인트(API 경로)를 중앙에서 관리하는 클래스
class ApiConfig {
  static const String baseUrl =
      'https://joya-nonstrategical-supersmartly.ngrok-free.dev';

// ✅ 상대 경로를 전체 URL로 바꿔주는 메서드
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://via.placeholder.com/150";
    }
    if (path.startsWith('http')) return path;

    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  // 인증 엔드포인트
  static const String login = '/auth/login'; // POST (이메일/비밀번호 로그인)
  static const String register = '/auth/register'; // POST (소비자 회원가입)
  static const String logout = '/auth/logout'; // POST (로그아웃, 토큰 무효화)
  static const String refresh = '/auth/refresh'; // POST (액세스 토큰 갱신)
  static const String check = '/auth/check'; // GET (이메일 중복 체크)

  // 매장_상품조회 엔드포인트
  static const String stores = '/stores'; // GET (매장 목록 조회, 반경 필터+페이징)
  static String storeDetail(int storeId) =>
      '/stores/$storeId'; // GET (매장 상세 조회)
  static String storeProducts(int storeId) =>
      '/stores/$storeId/products'; // GET (매장별 제품 목록 조회)
  static String storeHours(int storeId) =>
      '/stores/$storeId/hours'; // GET (매장 운영시간 조회)

  // 장바구니 엔드포인트
  static const String cart = '/cart/'; // GET (장바구니 조회), DELETE (장바구니 전체 비우기)
  static const String cartItems = '/cart/items/'; // POST (장바구니 상품 추가)
  static String cartItem(String cartItemId) => '/cart/items/$cartItemId/';

  // 주문 엔드포인트
  static const String orders = '/orders/'; // GET (내 주문 목록 조회), POST (주문 생성)
  static String orderDetail(int orderId) =>
      '/orders/$orderId/'; // GET (주문 상세 조회)
  static String orderCancel(int orderId) =>
      '/orders/$orderId/cancel/'; // PATCH (주문 취소)

  // 유저_마이페이지 엔드포인트
  static const String usersMe = '/users/me'; // GET (내 프로필 조회), PUT (내 프로필 수정)
  static const String usersMePassword = '/users/me/password'; // PATCH (비밀번호 변경)
  static const String usersMeProfileImage =
      '/users/me/profile-image'; // POST (프로필 이미지 업로드)
  static const String usersMeSavings = '/users/me/savings'; // GET (절약 금액 합계 조회)

  // 즐겨찾기 엔드포인트
  static const String favorites = '/users/me/favorites'; // GET (즐겨찾기한 매장 목록 조회)
  static String toggleFavorite(int storeId) =>
      '/stores/$storeId/favorite/'; // POST (즐겨찾기 추가), DELETE (즐겨찾기 해제)

  // 위치 엔드포인트
  static const String locations =
      '/users/me/locations'; // GET (저장된 위치 로그 목록), POST (위치 저장)
  static String deleteLocation(int logId) =>
      '/users/me/locations/$logId'; // DELETE (위치 삭제)

  static String ownerOrders(int storeId) => '/owner/stores/$storeId/orders/';

  static String ownerOrderHistory(int storeId) =>
      '/owner/stores/$storeId/orders/history/';

  static String ownerOrderDetail(int storeId, int orderId) =>
      '/owner/stores/$storeId/orders/$orderId/';

  static String ownerOrderAccept(int storeId, int orderId) =>
      '/owner/stores/$storeId/orders/$orderId/accept/';

  static String ownerOrderCancel(int storeId, int orderId) =>
      '/owner/stores/$storeId/orders/$orderId/cancel/';

  static String ownerOrderComplete(int storeId, int orderId) =>
      '/owner/stores/$storeId/orders/$orderId/complete/';

  // 추천 엔드포인트
  static const String recommendations =
      '/users/me/recommendations'; // GET (ML 서버 기반 매장 추천)

  // 핫딜 엔드포인트
  static const String hotdeal = '/products/hotdeal/'; // GET (핫딜 상품 목록)

  // 재주문 엔드포인트
  static String reorder(int orderId) =>
      '/orders/$orderId/reorder/'; // POST (이전 주문 재주문)

  // 카테고리 엔드포인트
  static const String categories = '/categories/'; // GET (카테고리 목록)
}
