import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/word.dart';
import '../../domain/entities/study_record.dart';
import '../../domain/repositories/word_repository.dart';
import '../../domain/usecases/sm2_algorithm.dart';

/// WordRepository 的具体实现
/// 负责从 SQLite 读写数据，并调用 SM-2 算法更新学习记录
class WordRepositoryImpl implements WordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Word>> getTodayReviewWords() async {
    final db = await _dbHelper.database;

    // 获取今天的日期（不含时间）
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day)
        .toIso8601String();

    // 查询今天需要复习的单词
    // 关联 words 和 study_records 表
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT w.*, s.*
      FROM words w
      INNER JOIN study_records s ON w.id = s.word_id
      WHERE DATE(s.next_review_date) <= DATE(?)
      ORDER BY s.next_review_date ASC
    ''', [todayStr]);

    // 把查询结果转换成 Word 对象列表
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  @override
  Future<List<Word>> getAllWords() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('words');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  @override
  Future<Word?> getWordById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  @override
  Future<StudyRecord> studyWord({
    required int wordId,
    required int quality,
  }) async {
    final db = await _dbHelper.database;

    // 1. 获取当前学习记录
    final record = await getStudyRecord(wordId);
    if (record == null) {
      throw Exception('未找到单词的学习记录');
    }

    // 2. 调用 SM-2 算法计算新的学习状态
    final result = Sm2Algorithm.calculate(
      quality: quality,
      currentInterval: record.interval,
      currentEaseFactor: record.easeFactor,
      reviewCount: record.reviewCount,
    );

    // 3. 更新学习记录
    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: result.newInterval));

    final updatedRecord = record.copyWith(
      reviewCount: result.newReviewCount,
      easeFactor: result.newEaseFactor,
      interval: result.newInterval,
      nextReviewDate: nextReviewDate,
      lastReviewDate: now,
      masteryLevel: quality >= 4 ? record.masteryLevel + 1 : record.masteryLevel,
    );

    // 4. 保存到数据库
    await db.update(
      'study_records',
      updatedRecord.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );

    return updatedRecord;
  }

  @override
  Future<StudyRecord?> getStudyRecord(int wordId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_records',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
    if (maps.isEmpty) return null;
    return StudyRecord.fromMap(maps.first);
  }

  @override
  Future<Map<String, int>> getTodayStats() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day)
        .toIso8601String();

    // 今日待复习数量
    final List<Map<String, dynamic>> reviewResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM study_records
      WHERE next_review_date <= ?
    ''', [todayStr]);
    final int todayReview = reviewResult.first['count'] as int;

    // 总已掌握数量（mastery_level >= 5 表示已掌握）
    final List<Map<String, dynamic>> masteredResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM study_records
      WHERE mastery_level >= 5
    ''');
    final int mastered = masteredResult.first['count'] as int;

    // 总单词数
    final List<Map<String, dynamic>> totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM words
    ''');
    final int total = totalResult.first['count'] as int;

    return {
      'todayReview': todayReview,
      'mastered': mastered,
      'total': total,
    };
  }

  @override
  Future<void> initializeWords() async {
    await _dbHelper.insertInitialWords();
  }
}