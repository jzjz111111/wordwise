import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier();
});

class AuthNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );


    print('📌 signUp 响应: user=${response.user}, session=${response.session}');

    if (response.user != null) {
      try {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'username': email.split('@').first,
          'avatar_url': null,
        });
        print('✅ profiles 创建成功');
      } catch (e) {
        print('❌ 创建 profiles 失败: $e');
      }
    } else {
      print('⚠️ response.user 为 null，无法创建 profiles');
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}