import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/favorite_word_repository.dart';
import '../datasources/favorite_word_remote_datasource.dart';

class FavoriteWordRepositoryImpl implements FavoriteWordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FavoriteWordRemoteDatasource _remote = FavoriteWordRemoteDatasource();

  @override
  Future<List<Word>> getFavorites(String userId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT w.* FROM favorite_words f
      INNER JOIN words w ON f.word_id = w.id
      WHERE f.user_id = ? 
      ORDER BY f.created_at DESC
    ''', [userId]);
    return res.map((e) => Word.fromMap(e)).toList();
  }

  @override
  Future<void> addFavorite(String userId, int wordId) async {
    final db = await _dbHelper.database;
    // 本地去重
    final exist = await db.query(
      'favorite_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );
    if (exist.isNotEmpty) return;

    // 1. 先写入本地
    final now = DateTime.now().toIso8601String();
    await db.insert('favorite_words', {
      'word_id': wordId,
      'user_id': userId,
      'created_at': now,
    });

    // 2. 异步同步云端
    _remote.pushFavorite(wordId).catchError((_) {});
  }

  @override
  Future<void> removeFavorite(String userId, int wordId) async {
    final db = await _dbHelper.database;
    // 1. 先删除本地
    await db.delete(
      'favorite_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );

    // 2. 异步同步云端
    _remote.deleteFavorite(wordId).catchError((_) {});
  }

  @override
  Future<bool> isFavorite(String userId, int wordId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'favorite_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );
    return res.isNotEmpty;
  }

  /// 从云端拉取数据合并到本地（登录时调用）
  Future<void> pullFromCloud(String userId) async {
    try {
      final cloudList = await _remote.pullAllFavorites();
      if (cloudList.isEmpty) return;

      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final item in cloudList) {
        batch.insert(
          'favorite_words',
          {
            'word_id': item['word_id'],
            'user_id': userId,
            'created_at': item['created_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(noResult: true);
    } catch (_) {
      // 拉取失败静默处理
    }
  }
}