/// 서버 /posts/ 응답을 파싱하는 모델
class PostModel {
  final int postId;
  final int userId;
  final String userName;
  final String postName;
  final String? content;
  final double? postLat;
  final double? postLong;
  final int? storeId;
  final String? storeName;
  final String? imgUrl;
  final double? distanceKm;
  final String regDt;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.postName,
    this.content,
    this.postLat,
    this.postLong,
    this.storeId,
    this.storeName,
    this.imgUrl,
    this.distanceKm,
    required this.regDt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '',
      postName: json['post_name'] as String? ?? '',
      content: json['content'] as String?,
      postLat: (json['post_lat'] as num?)?.toDouble(),
      postLong: (json['post_long'] as num?)?.toDouble(),
      storeId: json['store_id'] as int?,
      storeName: json['store_name'] as String?,
      imgUrl: json['img_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      regDt: json['reg_dt'] as String? ?? '',
    );
  }
}
