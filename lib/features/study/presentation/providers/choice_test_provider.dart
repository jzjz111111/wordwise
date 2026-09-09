import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/word.dart';

/// 选择题测试状态
class ChoiceTestState {
  final List<Word> words;
  final int currentIndex;
  final bool isCorrect;
  final bool showResult;
  final List<Word> wrongWords;
  final bool isCompleted;
  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex;

  ChoiceTestState({
    required this.words,
    required this.currentIndex,
    required this.isCorrect,
    required this.showResult,
    required this.wrongWords,
    required this.isCompleted,
    required this.options,
    this.selectedIndex,
    this.correctIndex,
  });

  factory ChoiceTestState.initial() {
    return ChoiceTestState(
      words: [],
      currentIndex: 0,
      isCorrect: false,
      showResult: false,
      wrongWords: [],
      isCompleted: false,
      options: [],
      selectedIndex: null,
      correctIndex: null,
    );
  }

  Word? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  int get totalCount => words.length;

  static const _unset = Object();

  ChoiceTestState copyWith({
    List<Word>? words,
    int? currentIndex,
    bool? isCorrect,
    bool? showResult,
    List<Word>? wrongWords,
    bool? isCompleted,
    List<String>? options,
    Object? selectedIndex = _unset,   // 注意类型改为 Object?
    Object? correctIndex = _unset,
  }) {
    return ChoiceTestState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isCorrect: isCorrect ?? this.isCorrect,
      showResult: showResult ?? this.showResult,
      wrongWords: wrongWords ?? this.wrongWords,
      isCompleted: isCompleted ?? this.isCompleted,
      options: options ?? this.options,
      // 如果是哨兵值，表示未传，保留旧值；否则直接转型（允许为 null）
      selectedIndex: selectedIndex == _unset
          ? this.selectedIndex
          : selectedIndex as int?,
      correctIndex: correctIndex == _unset
          ? this.correctIndex
          : correctIndex as int?,
    );
  }
}

/// 选择题测试 Notifier
class ChoiceTestNotifier extends StateNotifier<ChoiceTestState> {
  ChoiceTestNotifier() : super(ChoiceTestState.initial());

  /// 加载测试单词
  void loadWords(List<Word> words) {
    if (words.isEmpty) {
      state = state.copyWith(isCompleted: true, words: []);
      return;
    }
    state = state.copyWith(
      words: words,
      currentIndex: 0,
      isCorrect: false,
      showResult: false,
      wrongWords: [],
      isCompleted: false,
      options: [],
      selectedIndex: null,
    );
    _generateOptionsForCurrent();
  }

  /// 为当前单词生成选项（直接使用预生成的干扰项）
  void _generateOptionsForCurrent() {
    final current = state.currentWord;
    if (current == null) return;

    // ✅ 直接从 distractors 字段读取干扰项
    if (current.distractors != null && current.distractors!.length >= 3) {
      final options = [current.word, ...current.distractors!]..shuffle();
      state = state.copyWith(
        options: options,
        correctIndex: options.indexOf(current.word),
      );
    } else {
      // ⚠️ 理论上不会触发，因为导入时所有单词都已生成干扰项
      // 但如果触发，说明数据有问题，用占位符填充
      final options = [current.word, '???', '???', '???']..shuffle();
      state = state.copyWith(
        options: options,
        correctIndex: options.indexOf(current.word),
      );
    }
  }

  /// 选择答案
  void selectAnswer(int index) {
    if (state.showResult) return;

    final current = state.currentWord;
    if (current == null) return;

    final isCorrect = state.correctIndex == index;

    state = state.copyWith(
      selectedIndex: index,
      isCorrect: isCorrect,
      showResult: true,
      wrongWords: isCorrect
          ? state.wrongWords
          : [...state.wrongWords, current],
    );
  }

  /// 下一个单词
  void nextWord() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.words.length) {
      state = state.copyWith(
        isCompleted: true,
        currentIndex: nextIndex,
        showResult: false,
      );
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        isCorrect: false,
        showResult: false,
        selectedIndex: null,
        options: [],
      );
      _generateOptionsForCurrent();
    }
  }


  void reset() {
    state = ChoiceTestState.initial();
  }
}

final choiceTestProvider = StateNotifierProvider<ChoiceTestNotifier, ChoiceTestState>((ref) {
  return ChoiceTestNotifier();
});
