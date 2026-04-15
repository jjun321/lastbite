// 백엔드 서버의 베이스 URL 및 각 엔드포인트(API 경로)를 중앙에서 관리하는 클래스
class ApiConfig {
  static const String baseUrl =
      'https://joya-nonstrategical-supersmartly.ngrok-free.dev';

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
  static String cartItem(int cartItemId) =>
      '/cart/items/$cartItemId/'; // PATCH (수량 변경), DELETE (상품 개별 삭제)

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
}
