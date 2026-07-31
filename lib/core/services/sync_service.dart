import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取当前用户ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// 上传本地数据到云端
  Future<void> uploadToCloud() async {
    final userId = _userId;
    if (userId == null) return;

    final db = await _dbHelper.database;

    // 获取本地所有学习记录
    final List<Map<String, dynamic>> localRecords = await db.query(
      'study_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (var record in localRecords) {
      try {
        final data = {
          'user_id': userId,
          'word_id': record['word_id'],
          'review_count': record['review_count'],
          'ease_factor': record['ease_factor'],
          'interval': record['interval'],
          'next_review_date': record['next_review_date'],
          'last_review_date': record['last_review_date'],
          'mastery_level': record['mastery_level'],
          'last_review_quality': record['last_review_quality'],
          'synced_at': DateTime.now().toIso8601String(),
        };

        // 检查云端是否已有该记录
        final existing = await _supabase
            .from('study_records')
            .select()
            .eq('user_id', userId)
            .eq('word_id', record['word_id'])
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('study_records').insert(data);
        } else {
          await _supabase
              .from('study_records')
              .update(data)
              .eq('user_id', userId)
              .eq('word_id', record['word_id']);
        }
      } catch (e) {
        print('同步失败 (word_id=${record['word_id']}): $e');
      }
    }
  }

  /// 从云端下载数据到本地
  Future<void> downloadFromCloud() async {
    final userId = _userId;
    if (userId == null) return;

    final db = await _dbHelper.database;

    // 从云端获取该用户的所有学习记录
    final List<dynamic> cloudRecords = await _supabase
        .from('study_records')
        .select()
        .eq('user_id', userId);

    for (var record in cloudRecords) {
      final wordId = record['word_id'];
      final existing = await db.query(
        'study_records',
        where: 'word_id = ? AND user_id = ?',
        whereArgs: [wordId, userId],
      );

      if (existing.isEmpty) {
        await db.insert('study_records', {
          'word_id': wordId,
          'user_id': userId,
          'review_count': record['review_count'] ?? 0,
          'ease_factor': record['ease_factor'] ?? 2.5,
          'interval': record['interval'] ?? 1,
          'next_review_date': record['next_review_date'] ?? DateTime.now().toIso8601String(),
          'last_review_date': record['last_review_date'],
          'mastery_level': record['mastery_level'] ?? 0,
          'last_review_quality': record['last_review_quality'] ?? -1,
        });
      } else {
        await db.update(
          'study_records',
          {
            'review_count': record['review_count'] ?? 0,
            'ease_factor': record['ease_factor'] ?? 2.5,
            'interval': record['interval'] ?? 1,
            'next_review_date': record['next_review_date'],
            'last_review_date': record['last_review_date'],
            'mastery_level': record['mastery_level'] ?? 0,
            'last_review_quality': record['last_review_quality'] ?? -1,
          },
          where: 'word_id = ? AND user_id = ?',
          whereArgs: [wordId, userId],
        );
      }
    }
  }

  /// 完整同步：先上传本地，再下载云端
  Future<void> syncAll() async {
    await uploadToCloud();
    await downloadFromCloud();
    await uploadWrongWordsToCloud();
    await downloadWrongWordsFromCloud();
  }

  /// 上传错词到云端
  Future<void> uploadWrongWordsToCloud() async {
    final userId = _userId;
    if (userId == null) return;

    final db = await _dbHelper.database;

    // 获取本地所有错词
    final List<Map<String, dynamic>> localRecords = await db.query(
      'wrong_words',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (var record in localRecords) {
      try {
        final data = {
          'user_id': userId,
          'word_id': record['word_id'],
          'wrong_count': record['wrong_count'],
          'last_wrong_date': record['last_wrong_date'],
          'synced_at': DateTime.now().toIso8601String(),
        };

        // 检查云端是否已有该记录
        final existing = await _supabase
            .from('wrong_words')
            .select()
            .eq('user_id', userId)
            .eq('word_id', record['word_id'])
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('wrong_words').insert(data);
        } else {
          await _supabase
              .from('wrong_words')
              .update(data)
              .eq('user_id', userId)
              .eq('word_id', record['word_id']);
        }
      } catch (e) {
        print('错词同步失败 (word_id=${record['word_id']}): $e');
      }
    }
  }

  /// 从云端下载错词到本地
  Future<void> downloadWrongWordsFromCloud() async {
    final userId = _userId;
    if (userId == null) return;

    final db = await _dbHelper.database;

    // 从云端获取该用户的所有错词
    final List<dynamic> cloudRecords = await _supabase
        .from('wrong_words')
        .select()
        .eq('user_id', userId);

    for (var record in cloudRecords) {
      final wordId = record['word_id'];
      final existing = await db.query(
        'wrong_words',
        where: 'word_id = ? AND user_id = ?',
        whereArgs: [wordId, userId],
      );

      if (existing.isEmpty) {
        await db.insert('wrong_words', {
          'word_id': wordId,
          'user_id': userId,
          'wrong_count': record['wrong_count'] ?? 1,
          'last_wrong_date': record['last_wrong_date'] ?? DateTime.now().toIso8601String(),
        });
      } else {
        await db.update(
          'wrong_words',
          {
            'wrong_count': record['wrong_count'] ?? 1,
            'last_wrong_date': record['last_wrong_date'],
          },
          where: 'word_id = ? AND user_id = ?',
          whereArgs: [wordId, userId],
        );
      }
    }
  }

  /// 从云端删除单个错词
  Future<void> deleteWrongWordFromCloud(int wordId) async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('wrong_words')
        .delete()
        .eq('user_id', userId)
        .eq('word_id', wordId);
  }

  /// 从云端清空所有错词
  Future<void> clearWrongWordsFromCloud() async {
    final userId = _userId;
    if (userId == null) return;

    await _supabase
        .from('wrong_words')
        .delete()
        .eq('user_id', userId);
  }
}