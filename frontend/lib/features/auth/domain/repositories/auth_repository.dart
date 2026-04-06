import 'package:frontend/features/auth/data/models/login_model.dart';
import 'package:frontend/features/auth/data/models/signup_model.dart';

// 도메인 레이어에서 추상화된 인증 기능(로그인, 회원가입 등)들을 정의하는 인터페이스
// 데이터가 어디서 오는지(Remote/Local)에 상관없이 애플리케이션에서 실행될 핵심 동작을 명시함
abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<SignupResponse> signup(SignupRequest request);
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<UserModel?> getUser();
}
