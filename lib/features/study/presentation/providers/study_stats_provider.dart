import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/study_stats_repository.dart';
import '../../data/repositories/study_stats_repository_impl.dart';
import '../../domain/entities/study_stats.dart';

final studyStatsRepositoryProvider = Provider<StudyStatsRepository>((ref) {
  return StudyStatsRepositoryImpl();
});

/// 近7天每日学习数量
final dailyStudyStatsProvider = FutureProvider<List<DailyStudyStats>>((ref) async {
  final repository = ref.watch(studyStatsRepositoryProvider);
  return await repository.getDailyStudyStats(days: 7);
});

/// 掌握程度分布
final masteryDistributionProvider = FutureProvider<MasteryDistribution>((ref) async {
  final repository = ref.watch(studyStatsRepositoryProvider);
  return await repository.getMasteryDistribution();
});

/// 总学习统计
final totalStudyStatsProvider = FutureProvider<TotalStudyStats>((ref) async {
  final repository = ref.watch(studyStatsRepositoryProvider);
  return await repository.getTotalStudyStats();
});