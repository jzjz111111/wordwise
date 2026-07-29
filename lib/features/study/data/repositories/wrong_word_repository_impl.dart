import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/wrong_word_repository.dart';

class WrongWordRepositoryImpl implements WrongWordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ✅ 获取当前登录用户的 ID
  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  @override
  Future<void> addWrongWord(int wordId) async {
    final db = await _dbHelper.database;
    final userId = _userId;

    // 检查是否已存在（当前用户的错词）
    final existing = await db.query(
      'wrong_words',
      where: 'word_id = ? AND user_id = ?',
      whereArgs: [wordId, userId],
    );

    if (existing.isNotEmpty) {
      // 存在则更新错误次数和日期
      await db.update(
        'wrong_words',
        {
          'wrong_count': (existing.first['wrong_count'] as int) + 1,
          'last_wrong_date': DateTime.now().toIso8601String(),
        },
        where: 'word_id = ? AND user_id = ?',
        whereArgs: [wordId, userId],
      );
    } else {
      // 不存在则插入（带上 user_id）
      await db.insert('wrong_words', {
        'word_id': wordId,
        'user_id': userId,  // ✅ 新增
        'wrong_count': 1,
        'last_wrong_date': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<List<Word>> getAllWrongWords() async {
    final db = await _dbHelper.database;
    final userId = _userId;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT w.*
      FROM words w
      INNER JOIN wrong_words ww ON w.id = ww.word_id
      WHERE ww.user_id = ?
      ORDER BY ww.last_wrong_date DESC
    ''', [userId]);
    print('📊 查询到错词数量: ${maps.length}');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  @override
  Future<void> clearWrongWords() async {
    final db = await _dbHelper.database;
    final userId = _userId;
    await db.delete(
      'wrong_words',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> removeWrongWord(int wordId) async {
    final db = await _dbHelper.database;
    final userId = _userId;
    await db.delete(
      'wrong_words',
      where: 'word_id = ? AND user_id = ?',
      whereArgs: [wordId, userId],
    );
  }
}