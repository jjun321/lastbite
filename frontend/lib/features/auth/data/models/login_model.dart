/// 로그인 API 호출 시 벡엔드로 전송할 데이터(ID, PW)를 저장하고 JSON으로 변환하는 DTO 클래스

class LoginRequest {
  final String userEmail;
  final String userPassword;

  LoginRequest({required this.userEmail, required this.userPassword});

  Map<String, dynamic> toJson() {
    return {'user_email': userEmail, 'user_password': userPassword};
  }
}

// 로그인 성공 후 백엔드 서버에서 전달하는 성공 여부, 메시지, 그리고 토큰(JWT)과 유저 정보를 담는 모델 클래스
class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  LoginData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel {
  final int userId;
  final String userName;
  final String userEmail;
  final String userType;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userType: json['user_type'] ?? '',
    );
  }

  bool get isOwner => userType == 'U02';
  bool get isConsumer => userType == 'U01';
}
