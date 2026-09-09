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

/// 掌握程度分布（按 mastery_level 分三档）
class MasteryDistribution {
  final int basic;        // 初级掌握 (mastery_level < 3)
  final int intermediate; // 中级掌握 (mastery_level >= 3 && < 5)
  final int advanced;     // 高级掌握 (mastery_level >= 5)

  MasteryDistribution({
    required this.basic,
    required this.intermediate,
    required this.advanced,
  });

  int get total => basic + intermediate + advanced;
}

/// 总学习统计
class TotalStudyStats {
  final int totalDays;      // 总学习天数
  final int totalWords;     // 总学习单词数（至少学过1次）
  final int consecutiveDays; // 连续学习天数
  final int totalMastered;  // 总已掌握单词数（mastery_level >= 5）

  TotalStudyStats({
    required this.totalDays,
    required this.totalWords,
    required this.consecutiveDays,
    required this.totalMastered,
  });
}