import '../entities/word.dart';
import '../entities/study_record.dart';

/// 单词仓库接口
/// 定义所有和单词数据相关的操作
/// 具体的实现类在 data/repositories/ 中
abstract class WordRepository {
  /// 获取今日需要复习的单词列表
  /// 返回 List<Word>，每个 Word 包含对应的学习记录信息
  Future<List<Word>> getTodayReviewWords({String? category});

  /// 获取所有单词（用于词库管理）
  Future<List<Word>> getAllWords();

  /// 根据 ID 获取单个单词
  Future<Word?> getWordById(int id);

  /// 学习一个单词
  /// [wordId] 单词 ID
  /// [quality] 用户评分（0-5）
  /// 返回更新后的学习记录
  Future<StudyRecord> studyWord({
    required int wordId,
    required int quality,
  });

  /// 获取单词的学习记录
  Future<StudyRecord?> getStudyRecord(int wordId);

  /// 获取今日学习统计
  Future<Map<String, int>> getTodayStats({String? category});

  /// 初始化词库（插入初始单词）
  Future<void> initializeWords();
  /// 获取单词详情（包含学习记录）
  Future<(Word, StudyRecord?)> getWordDetail(int wordId);
}