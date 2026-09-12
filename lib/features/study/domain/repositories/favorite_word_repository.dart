import '../entities/word.dart';

abstract class FavoriteWordRepository {
  /// 获取用户指定分类下的收藏列表
  Future<List<Word>> getFavorites(String userId);

  /// 添加单词到收藏本
  Future<void> addFavorite(String userId, int wordId);

  /// 取消收藏单词
  Future<void> removeFavorite(String userId, int wordId);

  /// 判断单词是否已收藏
  Future<bool> isFavorite(String userId, int wordId);
}