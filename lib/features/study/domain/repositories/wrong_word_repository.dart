import '../entities/word.dart';

abstract class WrongWordRepository {
  /// 添加错词
  Future<void> addWrongWord(int wordId);

  /// 获取所有错词（按时间倒序）
  Future<List<Word>> getAllWrongWords();

  /// 清空错词本
  Future<void> clearWrongWords();

  /// 删除单个错词
  Future<void> removeWrongWord(int wordId);
}