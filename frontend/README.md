# 🍽️ Last Bite - Flutter Frontend

> 소비자 및 소상공인 점주 맞춤형 위치기반 식품 마감할인 앱


# 📌 커밋 규칙
| Prefix        |             의미            | 예시                              |
| :------------ | :-----------------------: | :------------------------------ |
| **feat:**     |    :sparkles: 새로운 기능 추가   | `feat: 시작 버튼 활성화 로직 구현`         |
| **fix:**      |        :bug: 버그 수정        | `fix: Spinner 색상 불일치 문제 해결`     |
| **refactor:** |     :hammer: 코드 구조 개선     | `refactor: Activity 코드 정리`      |
| **style:**    |        :art: 코드 포맷팅       | `style: XML 들여쓰기 수정`            |
| **docs:**     |       :pencil: 문서 수정      | `docs: 커밋 규칙 README에 추가`        |
| **chore:**    |        :gear: 설정 변경       | `chore: gradle 버전 업데이트`         |
| **test:**     | :white_check_mark: 테스트 코드 | `test: 입력 검증 테스트 추가`            |
| **perf:**     |       :rocket: 성능 개선      | `perf: 로딩 속도 개선`                |
| **build:**    | :construction_site: 빌드 수정 | `build: CI 스크립트 수정`             |
| **ci:**       |      :robot: CI/CD 수정     | `ci: GitHub Actions 설정 변경`      |
| **revert:**   |      :rewind: 커밋 되돌림      | `revert: "feat: 온보딩 UI 추가" 되돌림` |

---

## 📂 프로젝트 구조

```
frontend/lib/
├── main.dart                          # 앱 실행 시작점
│
├── app/                               # 앱 전역 설정
│   ├── app.dart                       # MaterialApp 위젯 (루트)
│   ├── router/
│   │   └── app_router.dart            # GoRouter 라우팅 정의
│   └── config/
│       └── app_config.dart            # 환경 변수 (API URL 등)
│
├── core/                              # 전역 공통 코드
│   ├── constants/
│   │   ├── api_constants.dart         # API 엔드포인트 상수
│   │   └── app_colors.dart            # 앱 컬러 팔레트
│   ├── theme/
│   │   └── app_theme.dart             # Material 테마 설정
│   ├── utils/
│   │   ├── date_utils.dart            # 날짜/시간 포맷 유틸
│   │   └── validators.dart            # 입력값 검증 유틸
│   └── widgets/
│       ├── custom_button.dart         # 공통 버튼 위젯
│       ├── custom_text_field.dart     # 공통 텍스트필드 위젯
│       ├── loading_indicator.dart     # 로딩 인디케이터
│       └── error_dialog.dart          # 에러 다이얼로그
│
├── data/                              # 데이터 레이어 (외부 통신)
│   ├── datasources/
│   │   └── remote/
│   │       ├── api_client.dart        # Dio HTTP 클라이언트 설정
│   │       ├── auth_api.dart          # 인증 API 호출
│   │       ├── store_api.dart         # 매장 API 호출
│   │       ├── product_api.dart       # 상품 API 호출
│   │       └── order_api.dart         # 주문 API 호출
│   ├── models/                        # JSON ↔ Dart 변환용 모델 (DTO)
│   │   │                              #   서버 응답 JSON을 Dart 객체로 변환하는 역할
│   │   │                              #   fromJson() / toJson() 메서드 포함
│   │   ├── user_model.dart            # 유저 DTO: userId, email, name, phone,
│   │   │                              #   userType(소비자/점주), profileImgId, regDt
│   │   ├── store_model.dart           # 매장 DTO: storeId, storeName, address,
│   │   │                              #   lat, lng, isClosed, workingTime, offDates
│   │   ├── product_model.dart         # 상품 DTO: productId, productName, category,
│   │   │                              #   oriPrice, disPrice, count, deadlineDt,
│   │   │                              #   freshness, isActive, images
│   │   └── order_model.dart           # 주문 DTO: orderId, storeId, userId,
│   │                                  #   orderStatus, pickupDt, orderItems[]
│   └── repositories/                  # Repository 구현체
│       │                              #   domain/repositories의 추상 인터페이스를 구현
│       │                              #   datasources/remote API를 호출하여 실제 데이터를 가져옴
│       ├── auth_repository_impl.dart  # 인증 구현: 로그인, 회원가입, 토큰갱신,
│       │                              #   소셜로그인 API 호출 → User 엔티티 변환
│       ├── store_repository_impl.dart # 매장 구현: 매장 CRUD, 위치기반 주변매장 조회,
│       │                              #   영업시간/휴무일 관리 API 호출
│       ├── product_repository_impl.dart # 상품 구현: 상품 등록/수정/삭제,
│       │                              #   카테고리별 조회, 핫딜 목록 API 호출
│       └── order_repository_impl.dart # 주문 구현: 예약주문 생성, 주문취소,
│                                      #   주문내역 조회, 주문상태 변경 API 호출
│
├── domain/                            # 도메인 레이어 (비즈니스 로직)
│   │                                  #   외부 의존성 없는 순수 Dart 코드만 존재
│   │                                  #   앱의 핵심 비즈니스 규칙을 정의
│   ├── entities/                      # 순수 도메인 객체 (Entity)
│   │   │                              #   UI와 data 레이어 모두에서 사용하는 핵심 데이터 구조
│   │   │                              #   JSON 변환 로직 없이 순수 필드만 정의
│   │   ├── user.dart                  # 유저 엔티티: id, email, name, phone, userType
│   │   │                              #   소비자(U01)와 점주(U02) 공통 사용자 정보
│   │   ├── store.dart                 # 매장 엔티티: id, name, address, lat/lng,
│   │   │                              #   isClosed, 영업시간, 점주 ID
│   │   ├── product.dart               # 상품 엔티티: id, name, category, 원가, 할인가,
│   │   │                              #   재고수량, 마감시간, 신선도, 활성여부
│   │   └── order.dart                 # 주문 엔티티: id, store, user, 주문상태
│   │                                  #   (CREATED/PAID/PICKED_UP/CANCELLED),
│   │                                  #   픽업시간, 주문상품 목록
│   └── repositories/                  # Repository 인터페이스 (추상 클래스)
│       │                              #   data 레이어의 구현체가 이 인터페이스를 구현함
│       │                              #   features 레이어는 이 인터페이스에만 의존 (의존성 역전)
│       ├── auth_repository.dart       # 인증 인터페이스: login(), register(),
│       │                              #   refreshToken(), socialLogin(), getMe()
│       ├── store_repository.dart      # 매장 인터페이스: getStores(), getStoreById(),
│       │                              #   getNearbyStores(), createStore(), updateStore()
│       ├── product_repository.dart    # 상품 인터페이스: getProducts(), createProduct(),
│       │                              #   updateProduct(), getHotDeals()
│       └── order_repository.dart      # 주문 인터페이스: createOrder(), getOrders(),
│                                      #   cancelOrder(), updateOrderStatus()
│
├── services/                          # 외부 서비스 연동
│   ├── location/
│   │   └── location_service.dart      # GPS 위치 획득
│   └── notification/
│       └── push_notification_service.dart  # FCM 푸시 알림
│
└── features/                          # 기능별 모듈
    ├── auth/                          # 🔐 인증
    │   └── presentation/
    │       ├── pages/
    │       │   ├── welcome_page.dart       # 앱 시작 화면
    │       │   ├── login_page.dart         # 로그인
    │       │   ├── signup_page.dart      # 회원가입
    │       │   ├── pwfind_page.dart      # 비밀번호 찾기
    │       │   ├── pwchange_page.dart      # 비밀번호 변경
    │       │   └── owner_entry_page.dart   # 점주 시작 화면
    │       ├── widgets/                    # auth 전용 위젯
    │       └── providers/
    │           └── auth_provider.dart      # 인증 상태 관리
    │
    ├── consumer/                      # 🛒 소비자 기능
    │   ├── home/
    │   │   └── presentation/
    │   │       ├── pages/
    │   │       │   └── consumer_home_page.dart    # 소비자 홈 (지도+리스트)
    │   │       └── widgets/
    │   │           ├── store_list_tile.dart        # 매장 리스트 아이템
    │   │           └── map_view.dart               # Naver Map 뷰
    │   ├── store_detail/
    │   │   └── presentation/pages/
    │   │       ├── store_detail_page.dart          # 매장 상세
    │   │       └── product_detail_page.dart        # 상품 상세
    │   ├── order/
    │   │   └── presentation/pages/
    │   │       ├── order_create_page.dart          # 예약 주문
    │   │       └── order_history_page.dart         # 주문 내역
    │   ├── search/
    │   │   └── presentation/pages/
    │   │       └── search_page.dart                # 검색/필터
    │   ├── wishlist/
    │   │   └── presentation/pages/
    │   │       └── wishlist_page.dart              # 찜 목록
    │   ├── board/
    │   │   └── presentation/pages/
    │   │       ├── board_list_page.dart            # 할인정보 제보 게시판
    │   │       └── board_write_page.dart           # 게시글 작성
    │   └── ai_recommend/
    │       └── presentation/pages/
    │           └── ai_recommend_page.dart          # AI 추천 / 핫딜
    │
    └── owner/                         # 🏪 점주 기능
        ├── store_manage/
        │   └── presentation/pages/
        │       ├── store_register_page.dart        # 매장 등록
        │       └── store_edit_page.dart            # 매장 정보 수정
        ├── product_manage/
        │   └── presentation/pages/
        │       ├── product_register_page.dart      # 상품/할인상품 등록
        │       └── product_list_page.dart          # 상품 목록 관리
        ├── order_manage/
        │   └── presentation/pages/
        │       └── order_status_page.dart          # 주문 현황 관리
        └── dashboard/
            └── presentation/pages/
                └── dashboard_page.dart             # 판매 현황 대시보드
```

### 기타 프로젝트 파일

```
frontend/
├── assets/
│   ├── images/
│   │   └── logo_lastbite.png          # 앱 로고
│   └── fonts/                         # 커스텀 폰트 (Pretendard 등)
├── android/                           # Android 네이티브 설정
├── ios/                               # iOS 네이티브 설정(예비)
├── pubspec.yaml                       # 패키지 및 에셋 설정
├── analysis_options.yaml              # 린트 설정
└── README.md                          # 이 문서
```

---

## 🏗️ 아키텍처

**Feature-First + Clean Architecture** 패턴을 사용합니다.

```
┌─────────────────────────────────────┐
│           features (UI)             │  ← 화면, 위젯, 상태관리(Provider)
├─────────────────────────────────────┤
│           domain (비즈니스)           │  ← Entity, Repository 인터페이스
├─────────────────────────────────────┤
│           data (데이터)              │  ← API 호출, JSON 모델, Repository 구현
├─────────────────────────────────────┤
│        core / services (공통)        │  ← 테마, 유틸, 위치, 알림
└─────────────────────────────────────┘
```

| 레이어 | 역할 | 의존 방향 |
|-------|------|----------|
| **features** | 사용자에게 보이는 화면과 상태 관리 | domain 참조 |
| **domain** | 순수 비즈니스 로직, 외부 의존성 없음 | 독립적 |
| **data** | 서버 통신, JSON 변환, Repository 구현 | domain 참조 |
| **core** | 앱 전역 공통 코드 (테마, 위젯, 상수) | 독립적 |
| **services** | 기기 기능 연동 (GPS, 푸시알림) | 독립적 |

---

## 🚀 실행 방법

### 사전 요구사항

- **Flutter SDK** 3.11.0 이상
- **Dart SDK** (Flutter에 포함)
- **Android Studio** (Android 에뮬레이터 및 SDK)
- **Xcode** (iOS 빌드 시, macOS만 해당)

### 1. Flutter SDK 설치 확인

```bash
flutter --version
flutter doctor
```

### 2. 의존성 설치

```bash
cd frontend
flutter pub get
```

### 3. 앱 실행

```bash
# Android 에뮬레이터 실행 후
flutter run

# 특정 기기 지정
flutter devices                    # 연결된 기기 목록 확인
flutter run -d <device_id>         # 특정 기기에서 실행

# Chrome(웹)에서 실행
flutter run -d chrome

# 디버그 모드 (기본)
flutter run --debug

# 릴리스 모드
flutter run --release
```

### 4. 빌드

```bash
# Android APK 빌드
flutter build apk --release

# Android App Bundle (Play Store 배포용)
flutter build appbundle --release

# iOS 빌드 (macOS에서만 가능)
flutter build ios --release
```

---

## 📦 주요 패키지

| 패키지 | 용도 |
|-------|------|
| `go_router` | 선언적 라우팅 |
| `flutter_riverpod` | 상태 관리 (예정) |
| `dio` | HTTP 클라이언트 (예정) |
| `flutter_naver_map` | Naver 지도 (예정) |
| `geolocator` | GPS 위치 획득 (예정) |
| `flutter_secure_storage` | JWT 토큰 보안 저장 (예정) |
| `firebase_messaging` | FCM 푸시 알림 (예정) |

---

## 📝 개발 컨벤션

### 파일 네이밍
- **페이지**: `*_page.dart` (예: `login_page.dart`)
- **위젯**: `*_widget.dart` 또는 서술적 이름 (예: `store_list_tile.dart`)
- **모델**: `*_model.dart` (예: `user_model.dart`)
- **Provider**: `*_provider.dart` (예: `auth_provider.dart`)

### 폴더 규칙
- 각 기능(feature)은 `features/` 아래에 독립적인 폴더로 관리
- UI 코드는 항상 `presentation/pages/` 또는 `presentation/widgets/` 하위에 배치
- API 통신 코드는 `data/datasources/remote/`에 집중

### 코드 스타일
- [Flutter 공식 스타일 가이드](https://dart.dev/effective-dart/style) 준수
- 모든 파일 상단에 역할 주석 작성 (기존 코드 스타일 유지)