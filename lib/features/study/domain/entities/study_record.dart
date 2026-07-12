/// 学习记录实体类
/// 对应数据库中的 study_records 表
class StudyRecord {
  final int? id;
  final int wordId;
  final int reviewCount;
  final double easeFactor;
  final int interval;
  final DateTime nextReviewDate;
  final DateTime? lastReviewDate;
  final int masteryLevel;

  StudyRecord({
    this.id,
    required this.wordId,
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    required this.nextReviewDate,
    this.lastReviewDate,
    this.masteryLevel = 0,
  });

  /// 从 Map 创建 StudyRecord 对象
  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as int?,
      wordId: map['word_id'] as int,
      reviewCount: map['review_count'] as int,
      easeFactor: map['ease_factor'] as double,
      interval: map['interval'] as int,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
      lastReviewDate: map['last_review_date'] != null
          ? DateTime.parse(map['last_review_date'] as String)
          : null,
      masteryLevel: map['mastery_level'] as int,
    );
  }

  /// 把 StudyRecord 对象转换成 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': wordId,
      'review_count': reviewCount,
      'ease_factor': easeFactor,
      'interval': interval,
      'next_review_date': nextReviewDate.toIso8601String(),
      'last_review_date': lastReviewDate?.toIso8601String(),
      'mastery_level': masteryLevel,
    };
  }

  /// 创建一个副本，并更新指定字段（用于学习后的状态更新）
  StudyRecord copyWith({
    int? id,
    int? wordId,
    int? reviewCount,
    double? easeFactor,
    int? interval,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    int? masteryLevel,
  }) {
    return StudyRecord(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      masteryLevel: masteryLevel ?? this.masteryLevel,
    );
  }
}