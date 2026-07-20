import '../entities/study_stats.dart';

abstract class StudyStatsRepository {
  /// 获取最近 N 天的每日学习数量
  Future<List<DailyStudyStats>> getDailyStudyStats({required int days});

  /// 获取掌握程度分布
  Future<MasteryDistribution> getMasteryDistribution();

  /// 获取总学习统计
  Future<TotalStudyStats> getTotalStudyStats();
}