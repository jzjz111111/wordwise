import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/study_stats.dart';
import '../../domain/repositories/study_stats_repository.dart';

class StudyStatsRepositoryImpl implements StudyStatsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ✅ 获取当前登录用户的 ID
  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  @override
  Future<List<DailyStudyStats>> getDailyStudyStats({required int days}) async {
    final db = await _dbHelper.database;
    final userId = _userId;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - days + 1);

    // ✅ 加上 user_id 过滤
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DATE(last_review_date) as date, COUNT(DISTINCT word_id) as count
      FROM study_records
      WHERE last_review_date IS NOT NULL
        AND DATE(last_review_date) >= DATE(?)
        AND user_id = ?
      GROUP BY DATE(last_review_date)
      ORDER BY DATE(last_review_date) ASC
    ''', [startDate.toIso8601String(), userId]);

    final Map<String, int> dataMap = {
      for (var row in results) row['date'] as String: row['count'] as int,
    };

    final List<DailyStudyStats> stats = [];
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - days + 1 + i);
      final dateStr = date.toIso8601String().substring(0, 10);
      stats.add(DailyStudyStats(
        date: date,
        count: dataMap[dateStr] ?? 0,
      ));
    }

    return stats;
  }

  @override
  Future<MasteryDistribution> getMasteryDistribution() async {
    final db = await _dbHelper.database;
    final userId = _userId;

    // ✅ 加上 user_id 过滤
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN mastery_level >= 5 THEN 1 ELSE 0 END) as mastered,
        SUM(CASE WHEN mastery_level > 0 AND mastery_level < 5 THEN 1 ELSE 0 END) as learning,
        SUM(CASE WHEN mastery_level == 0 THEN 1 ELSE 0 END) as not_started
      FROM study_records
      WHERE user_id = ?
    ''', [userId]);

    final row = results.first;
    return MasteryDistribution(
      mastered: row['mastered'] as int? ?? 0,
      learning: row['learning'] as int? ?? 0,
      notStarted: row['not_started'] as int? ?? 0,
    );
  }

  @override
  Future<TotalStudyStats> getTotalStudyStats() async {
    final db = await _dbHelper.database;
    final userId = _userId;

    // ✅ 总学习天数（加上 user_id 过滤）
    final List<Map<String, dynamic>> daysResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT DATE(last_review_date)) as count
      FROM study_records
      WHERE last_review_date IS NOT NULL AND user_id = ?
    ''', [userId]);
    final totalDays = daysResult.first['count'] as int? ?? 0;

    // ✅ 总学习单词数（加上 user_id 过滤）
    final List<Map<String, dynamic>> wordsResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT word_id) as count
      FROM study_records
      WHERE review_count > 0 AND user_id = ?
    ''', [userId]);
    final totalWords = wordsResult.first['count'] as int? ?? 0;

    // 连续学习天数
    final consecutiveDays = await _calculateConsecutiveDays(db, userId);

    return TotalStudyStats(
      totalDays: totalDays,
      totalWords: totalWords,
      consecutiveDays: consecutiveDays,
    );
  }

  // ✅ 加上 userId 参数
  Future<int> _calculateConsecutiveDays(Database db, String userId) async {
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT DATE(last_review_date) as date
      FROM study_records
      WHERE last_review_date IS NOT NULL AND user_id = ?
      ORDER BY DATE(last_review_date) DESC
    ''', [userId]);

    if (results.isEmpty) return 0;

    final dates = results.map((row) => DateTime.parse(row['date'] as String)).toList();
    final today = DateTime.now();

    int consecutive = 0;
    for (int i = 0; i < dates.length; i++) {
      final expectedDate = DateTime(today.year, today.month, today.day - i);
      if (i < dates.length) {
        final date = dates[i];
        if (date.year == expectedDate.year &&
            date.month == expectedDate.month &&
            date.day == expectedDate.day) {
          consecutive++;
        } else {
          break;
        }
      }
    }

    return consecutive;
  }
}