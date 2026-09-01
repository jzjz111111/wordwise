import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';
import '../../data/repositories/word_repository_impl.dart';
import 'word_category_provider.dart';

/// 提供 WordRepository 实例（全局单例）
final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepositoryImpl();
});

/// 提供今日单词列表（异步加载）
final todayWordsProvider = FutureProvider<List<Word>>((ref) async {
  final repository = ref.watch(wordRepositoryProvider);
  final category = ref.watch(currentCategoryProvider);
  return await repository.getTodayReviewWords(category: category);
});

/// 提供今日统计数据（异步加载）
final todayStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(wordRepositoryProvider);
  final category = ref.watch(currentCategoryProvider);
  return await repository.getTodayStats(category: category);
});

///提供未学习单词记录
final newWordsProvider = FutureProvider.family<List<Word>, int>((ref, count) async {
  final repository = ref.watch(wordRepositoryProvider);
  final category = ref.watch(currentCategoryProvider);
  return await repository.getNewWords(category: category, count: count);
});

/// 学习状态提供者（页面退出自动销毁状态，避免数据污染）
final studyStateProvider = StateNotifierProvider.autoDispose<StudyNotifier, StudyState>((ref) {
  return StudyNotifier(ref);
});


/// 学习状态
class StudyState {
  final List<Word> words;        // 今日所有单词
  final int currentIndex;        // 当前是第几个
  final bool isLoading;          // 是否加载中
  final String? error;           // 错误信息

  StudyState({
    required this.words,
    required this.currentIndex,
    required this.isLoading,
    this.error,
  });

  /// 初始状态
  factory StudyState.initial() {
    return StudyState(
      words: [],
      currentIndex: 0,
      isLoading: true,
    );
  }

  /// 是否还有更多单词
  bool get hasMoreWords => currentIndex < words.length;

  /// 当前显示的单词
  Word? get currentWord =>
      hasMoreWords ? words[currentIndex] : null;

  /// 学习进度（已学数量 / 总数）
  String get progress => '$currentIndex / ${words.length}';

  /// 复制并更新
  StudyState copyWith({
    List<Word>? words,
    int? currentIndex,
    bool? isLoading,
    String? error,
  }) {
    return StudyState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 学习状态控制器（Notifier）
class StudyNotifier extends StateNotifier<StudyState> {
  final Ref ref;

  StudyNotifier(this.ref) : super(StudyState.initial());

  /// 加载今日单词
  Future<void> loadTodayWords() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final repository = ref.read(wordRepositoryProvider);
      final words = await repository.getTodayReviewWords();

      if (words.isEmpty) {
        state = state.copyWith(
          words: [],
          currentIndex: 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          words: words,
          currentIndex: 0,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
// 加载指定单词列表（从详情页传入）
  void loadWords(List<Word> words) {
    state = state.copyWith(
      words: words,
      currentIndex: 0,
      isLoading: false,
      error: null,
    );
  }
  /// 评分并进入下一个单词
  Future<void> rateWord(int quality) async {
    print('🔥 rateWord 开始, quality=$quality');

    if (!state.hasMoreWords) {
      print('🔥 没有更多单词，退出');
      return;
    }

    final currentWord = state.currentWord!;
    print('🔥 当前单词: ${currentWord.word}, id=${currentWord.id}');

    try {
      final repository = ref.read(wordRepositoryProvider);
      print('🔥 调用 studyWord 前');
      await repository.studyWord(
        wordId: currentWord.id!,
        quality: quality,
      );
      print('🔥 studyWord 成功');

      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
      );
      print('🔥 索引更新为 ${state.currentIndex}');

    } catch (e) {
      print('🔥 出错: $e');
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  /// 重新加载
  Future<void> refresh() async {
    await loadTodayWords();
  }
}