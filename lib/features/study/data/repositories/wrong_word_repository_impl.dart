import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/wrong_word_repository.dart';

class WrongWordRepositoryImpl implements WrongWordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<void> addWrongWord(int wordId) async {
    final db = await _dbHelper.database;

    // 检查是否已存在
    final existing = await db.query(
      'wrong_words',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    if (existing.isNotEmpty) {
      // 存在则更新错误次数和日期
      await db.update(
        'wrong_words',
        {
          'wrong_count': (existing.first['wrong_count'] as int) + 1,
          'last_wrong_date': DateTime.now().toIso8601String(),
        },
        where: 'word_id = ?',
        whereArgs: [wordId],
      );
    } else {
      // 不存在则插入
      await db.insert('wrong_words', {
        'word_id': wordId,
        'wrong_count': 1,
        'last_wrong_date': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<List<Word>> getAllWrongWords() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT w.*
      FROM words w
      INNER JOIN wrong_words ww ON w.id = ww.word_id
      ORDER BY ww.last_wrong_date DESC
    ''');
    print('📊 查询到错词数量: ${maps.length}');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  @override
  Future<void> clearWrongWords() async {
    final db = await _dbHelper.database;
    await db.delete('wrong_words');
  }

  @override
  Future<void> removeWrongWord(int wordId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'wrong_words',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }
}