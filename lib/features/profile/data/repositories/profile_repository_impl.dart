import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      // 获取资料失败
      return null;
    }
  }

  @override
  Future<void> updateUsername(String userId, String username) async {
    await _supabase
        .from('profiles')
        .update({
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', userId);
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    await _supabase
        .from('profiles')
        .update({
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', userId);
  }

  @override
  Future<String> uploadAvatar(String userId, String filePath) async {
    final path = '$userId/avatar.jpg';
    final file = File(filePath);

    // 上传文件
    await _supabase.storage.from('avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    // 获取公开URL
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }
}