// 가게 정보를 담는 모델 클래스와 테스트용 더미 데이터를 정의한다.
// 나중에 백엔드 API 연동 시 이 모델을 확장하거나 교체한다.

class StoreModel {
  final int id;
  final String name;
  final List<String> categories;
  final double rating;
  final String closingTime;
  final bool isFavorite;
  final bool isAiRecommended;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const StoreModel({
    required this.id,
    required this.name,
    required this.categories,
    required this.rating,
    required this.closingTime,
    this.isFavorite = false,
    this.isAiRecommended = false,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  /// isFavorite 값만 토글한 새 인스턴스를 반환
  StoreModel copyWith({bool? isFavorite}) {
    return StoreModel(
      id: id,
      name: name,
      categories: categories,
      rating: rating,
      closingTime: closingTime,
      isFavorite: isFavorite ?? this.isFavorite,
      isAiRecommended: isAiRecommended,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// 테스트용 더미 데이터 (경희대 근처 좌표)
List<StoreModel> dummyStores = [
  const StoreModel(
    id: 1,
    name: '소금빵 가게',
    categories: ['소금빵', '휘낭시에', '베이글'],
    rating: 4.7,
    closingTime: '오후 6시 마감',
    isFavorite: false,
    latitude: 37.5835,
    longitude: 127.0100,
  ),
  const StoreModel(
    id: 2,
    name: '달콤 베이커리',
    categories: ['크로와상', '마카롱', '케이크'],
    rating: 4.5,
    closingTime: '오후 7시 마감',
    isFavorite: false,
    latitude: 37.5850,
    longitude: 127.0070,
  ),
  const StoreModel(
    id: 3,
    name: '행복한 빵집',
    categories: ['식빵', '바게트', '치아바타'],
    rating: 4.3,
    closingTime: '오후 5시 마감',
    isFavorite: false,
    isAiRecommended: true,
    latitude: 37.5810,
    longitude: 127.0120,
  ),
  const StoreModel(
    id: 4,
    name: '모닝글로리 베이커리',
    categories: ['스콘', '머핀', '타르트'],
    rating: 4.8,
    closingTime: '오후 8시 마감',
    isFavorite: false,
    latitude: 37.5860,
    longitude: 127.0050,
  ),
  const StoreModel(
    id: 5,
    name: '밀가루 공방',
    categories: ['호밀빵', '통밀빵', '잡곡빵'],
    rating: 4.1,
    closingTime: '오후 4시 마감',
    isFavorite: false,
    latitude: 37.5800,
    longitude: 127.0140,
  ),
];
