import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/study_stats.dart';
import '../../domain/repositories/study_stats_repository.dart';

class StudyStatsRepositoryImpl implements StudyStatsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<DailyStudyStats>> getDailyStudyStats({required int days}) async {
    final db = await _dbHelper.database;

    // 获取今天和 N 天前的日期
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - days + 1);

    // 按天分组统计学习记录（有 last_review_date 的记录算学习过）
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DATE(last_review_date) as date, COUNT(DISTINCT word_id) as count
      FROM study_records
      WHERE last_review_date IS NOT NULL
        AND DATE(last_review_date) >= DATE(?)
      GROUP BY DATE(last_review_date)
      ORDER BY DATE(last_review_date) ASC
    ''', [startDate.toIso8601String()]);

    // 构建完整日期列表（补全没有学习记录的日期）
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

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN mastery_level >= 5 THEN 1 ELSE 0 END) as mastered,
        SUM(CASE WHEN mastery_level > 0 AND mastery_level < 5 THEN 1 ELSE 0 END) as learning,
        SUM(CASE WHEN mastery_level == 0 THEN 1 ELSE 0 END) as not_started
      FROM study_records
    ''');

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

    // 总学习天数（有学习记录的不同日期数）
    final List<Map<String, dynamic>> daysResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT DATE(last_review_date)) as count
      FROM study_records
      WHERE last_review_date IS NOT NULL
    ''');
    final totalDays = daysResult.first['count'] as int? ?? 0;

    // 总学习单词数（至少复习过1次的单词）
    final List<Map<String, dynamic>> wordsResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT word_id) as count
      FROM study_records
      WHERE review_count > 0
    ''');
    final totalWords = wordsResult.first['count'] as int? ?? 0;

    // 连续学习天数
    final consecutiveDays = await _calculateConsecutiveDays(db);

    return TotalStudyStats(
      totalDays: totalDays,
      totalWords: totalWords,
      consecutiveDays: consecutiveDays,
    );
  }

  Future<int> _calculateConsecutiveDays(Database db) async {
    // 获取所有有学习记录的日期（去重，降序）
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT DATE(last_review_date) as date
      FROM study_records
      WHERE last_review_date IS NOT NULL
      ORDER BY DATE(last_review_date) DESC
    ''');

    if (results.isEmpty) return 0;

    final dates = results.map((row) => DateTime.parse(row['date'] as String)).toList();
    final today = DateTime.now();

    int consecutive = 0;
    // 从今天开始检查连续天数
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