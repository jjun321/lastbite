import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// 사장님 매장 이미지 로컬 캐시
/// 매장 등록/수정 화면에서 갤러리로 선택한 이미지를
/// 마이페이지/계정관리 페이지의 프로필 사진으로도 동일하게 보여주기 위한 헬퍼.
/// (백엔드에 별도 업로드 없이 로컬 파일 경로만 공유)
class OwnerImageCache {
  static const _key = 'owner_store_image_path';

  /// 이미지 경로 저장
  static Future<void> save(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  /// 저장된 이미지 파일 반환 (경로가 없거나 파일이 없으면 null)
  static Future<File?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file;
  }

  /// 캐시 제거
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
