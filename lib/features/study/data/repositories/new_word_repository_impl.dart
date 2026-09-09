import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/new_word_repository.dart';
import '../datasources/new_word_remote_datasource.dart';

class NewWordRepositoryImpl implements NewWordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NewWordRemoteDatasource _remote = NewWordRemoteDatasource();

  @override
  Future<List<Word>> getNewWords(String userId, String category) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT w.* FROM new_words n
      INNER JOIN words w ON n.word_id = w.id
      WHERE n.user_id = ? AND w.category = ?
      ORDER BY n.created_at DESC
    ''', [userId, category]);
    return res.map((e) => Word.fromMap(e)).toList();
  }

  @override
  Future<void> addNewWord(String userId, int wordId) async {
    final db = await _dbHelper.database;
    // 本地去重
    final exist = await db.query(
      'new_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );
    if (exist.isNotEmpty) return;

    // 1. 先写入本地
    final now = DateTime.now().toIso8601String();
    await db.insert('new_words', {
      'word_id': wordId,
      'user_id': userId,
      'created_at': now,
    });

    // 2. 异步同步云端，不阻塞主线程
    _remote.pushNewWord(wordId).catchError((_) {});
  }

  @override
  Future<void> removeNewWord(String userId, int wordId) async {
    final db = await _dbHelper.database;
    // 1. 先删除本地
    await db.delete(
      'new_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );

    // 2. 异步同步云端
    _remote.deleteNewWord(wordId).catchError((_) {});
  }

  @override
  Future<bool> isInNewWords(String userId, int wordId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'new_words',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
    );
    return res.isNotEmpty;
  }

  /// 从云端拉取数据合并到本地（登录时调用）
  Future<void> pullFromCloud(String userId) async {
    try {
      final cloudList = await _remote.pullAllNewWords();
      if (cloudList.isEmpty) return;

      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final item in cloudList) {
        batch.insert(
          'new_words',
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
      // 拉取失败静默处理，不影响本地使用
    }
  }
}