import 'package:frontend/features/auth/data/models/login_model.dart';

// 회원가입 시 백엔드 API 서버에 전달할 요청 데이터 모델
class SignupRequest {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userPassword;
  final String passwordConfirm;
  final String userType;

  SignupRequest({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userPassword,
    required this.passwordConfirm,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'user_password': userPassword,
      'password_confirm': passwordConfirm,
      'user_type': userType,
    };
  }
}

// 회원가입 성공 또는 실패 후 백엔드 서버에서 전달하는 응답 결과를 담는 모델
class SignupResponse {
  final bool success;
  final String message;
  final UserModel? data;

  SignupResponse({required this.success, required this.message, this.data});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
    );
  }
}
