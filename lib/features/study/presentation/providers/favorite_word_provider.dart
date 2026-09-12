import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/favorite_word_repository.dart';
import '../../data/repositories/favorite_word_repository_impl.dart';
import 'word_category_provider.dart';

/// 仓库实例
final favoriteWordRepositoryProvider = Provider<FavoriteWordRepository>((ref) {
  return FavoriteWordRepositoryImpl();
});

/// 收藏本列表：自动绑定当前用户 + 当前词库分类
final favoriteWordListProvider = FutureProvider<List<Word>>((ref) async {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return [];

  final repo = ref.watch(favoriteWordRepositoryProvider);
  return repo.getFavorites(userId);
});

/// 添加单词到收藏本
final addFavoriteProvider = Provider.family<void, int>((ref, wordId) {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return;

  final repo = ref.watch(favoriteWordRepositoryProvider);
  repo.addFavorite(userId, wordId);
  ref.invalidate(favoriteWordListProvider);
});

/// 取消收藏单词
final removeFavoriteProvider = Provider.family<void, int>((ref, wordId) {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return;

  final repo = ref.watch(favoriteWordRepositoryProvider);
  repo.removeFavorite(userId, wordId);
  ref.invalidate(favoriteWordListProvider);
});

/// 判断单词是否已收藏
final isFavoriteProvider = FutureProvider.family<bool, int>((ref, wordId) async {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return false;

  final repo = ref.watch(favoriteWordRepositoryProvider);
  return repo.isFavorite(userId, wordId);
});