import '../entities/profile.dart';

abstract class ProfileRepository {
  /// 获取当前用户资料
  Future<Profile?> getProfile(String userId);

  /// 更新昵称
  Future<void> updateUsername(String userId, String username);

  /// 更新头像
  Future<void> updateAvatar(String userId, String avatarUrl);

  /// 上传头像图片
  Future<String> uploadAvatar(String userId, String filePath);
}