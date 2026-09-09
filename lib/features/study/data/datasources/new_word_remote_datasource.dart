import 'package:supabase_flutter/supabase_flutter.dart';

class NewWordRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 拉取当前用户所有生词
  Future<List<Map<String, dynamic>>> pullAllNewWords() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _supabase
        .from('new_words')
        .select('word_id, created_at')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(res);
  }

  /// 上传单个生词到云端
  Future<void> pushNewWord(int wordId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('new_words').upsert({
      'word_id': wordId,
      'user_id': userId,
    }, onConflict: 'user_id, word_id');
  }

  /// 删除云端单个生词
  Future<void> deleteNewWord(int wordId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('new_words')
        .delete()
        .eq('user_id', userId)
        .eq('word_id', wordId);
  }

  /// 批量上传生词
  Future<void> batchPushNewWords(List<Map<String, dynamic>> list) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || list.isEmpty) return;

    final data = list.map((e) {
      return {
        'word_id': e['word_id'],
        'user_id': userId,
        'created_at': e['created_at'],
      };
    }).toList();

    await _supabase.from('new_words').upsert(
      data,
      onConflict: 'user_id, word_id',
    );
  }
}