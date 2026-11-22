import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/services/achievement_service.dart';
import '../../../profile/presentation/providers/achievement_provider.dart';
import '../../../profile/presentation/widgets/achievement_toast.dart';
import '../../../../main.dart' show rootNavigatorKey;
import '../../domain/entities/word.dart';
import '../../domain/repositories/favorite_word_repository.dart';
import '../../data/repositories/favorite_word_repository_impl.dart';

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
  ref.invalidate(isFavoriteProvider(wordId));
  // 收藏数变化，成就页也要刷新，同时检查是否解锁了"词汇收藏家"
  ref.invalidate(achievementListProvider);
  ref.invalidate(unlockedCountProvider);
  _checkFavoriteAchievements();
});

/// 检查收藏相关成就解锁
Future<void> _checkFavoriteAchievements() async {
  try {
    final context = rootNavigatorKey.currentContext;
    final newlyUnlocked = await AchievementService.instance.checkAndUnlock();
    if (newlyUnlocked.isNotEmpty && context != null) {
      AchievementToast.show(context, newlyUnlocked);
    }
  } catch (e) {
    debugPrint('收藏成就检查失败: $e');
  }
}

/// 取消收藏单词
final removeFavoriteProvider = Provider.family<void, int>((ref, wordId) {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return;

  final repo = ref.watch(favoriteWordRepositoryProvider);
  repo.removeFavorite(userId, wordId);
  ref.invalidate(favoriteWordListProvider);
  // 同步刷新按钮状态，否则图标不会变回未收藏
  ref.invalidate(isFavoriteProvider(wordId));
});

/// 判断单词是否已收藏
final isFavoriteProvider = FutureProvider.family<bool, int>((ref, wordId) async {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return false;

  final repo = ref.watch(favoriteWordRepositoryProvider);
  return repo.isFavorite(userId, wordId);
});