import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/new_word_repository.dart';
import '../../data/repositories/new_word_repository_impl.dart';
import 'word_category_provider.dart';

/// 仓库实例
final newWordRepositoryProvider = Provider<NewWordRepository>((ref) {
  return NewWordRepositoryImpl();
});

/// 生词本列表：自动绑定当前用户
final newWordListProvider = FutureProvider<List<Word>>((ref) async {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return [];

  final repo = ref.watch(newWordRepositoryProvider);
  return repo.getNewWords(userId);
});

/// 添加单词到生词本
final addNewWordProvider = Provider.autoDispose.family<void, int>((ref, wordId) {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return;

  final repo = ref.watch(newWordRepositoryProvider);
  repo.addNewWord(userId, wordId);
  ref.invalidate(newWordListProvider);
});

/// 从生词本移除单词
final removeNewWordProvider = Provider.autoDispose.family<void, int>((ref, wordId) {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return;

  final repo = ref.watch(newWordRepositoryProvider);
  repo.removeNewWord(userId, wordId);
  ref.invalidate(newWordListProvider);
});

/// 判断单词是否在生词本中
final isInNewWordProvider = FutureProvider.family<bool, int>((ref, wordId) async {
  final userId = ref.watch(authProvider).currentUser?.id;
  if (userId == null) return false;

  final repo = ref.watch(newWordRepositoryProvider);
  return repo.isInNewWords(userId, wordId);
});