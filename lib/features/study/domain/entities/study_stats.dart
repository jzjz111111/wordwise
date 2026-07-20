/// 每日学习统计
class DailyStudyStats {
  final DateTime date;
  final int count;

  DailyStudyStats({required this.date, required this.count});

  factory DailyStudyStats.fromMap(Map<String, dynamic> map) {
    return DailyStudyStats(
      date: DateTime.parse(map['date'] as String),
      count: map['count'] as int,
    );
  }
}

/// 掌握程度分布
class MasteryDistribution {
  final int mastered;   // 已掌握 (mastery_level >= 5)
  final int learning;   // 学习中 (mastery_level > 0 && mastery_level < 5)
  final int notStarted; // 未学习 (mastery_level == 0)

  MasteryDistribution({
    required this.mastered,
    required this.learning,
    required this.notStarted,
  });

  int get total => mastered + learning + notStarted;
}

/// 总学习统计
class TotalStudyStats {
  final int totalDays;      // 总学习天数
  final int totalWords;     // 总学习单词数（至少学过1次）
  final int consecutiveDays; // 连续学习天数

  TotalStudyStats({
    required this.totalDays,
    required this.totalWords,
    required this.consecutiveDays,
  });
}