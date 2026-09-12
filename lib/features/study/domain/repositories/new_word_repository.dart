import '../entities/word.dart';

abstract class NewWordRepository {
  /// 获取用户指定分类下的生词列表
  Future<List<Word>> getNewWords(String userId);

  /// 添加单词到生词本
  Future<void> addNewWord(String userId, int wordId);

  /// 从生词本移除单词
  Future<void> removeNewWord(String userId, int wordId);

  /// 判断单词是否在生词本中
  Future<bool> isInNewWords(String userId, int wordId);
}