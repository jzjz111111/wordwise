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
  final List<String> options;        // 当前题目的四个选项
  final int? selectedIndex;          // 用户选择的选项索引

  ChoiceTestState({
    required this.words,
    required this.currentIndex,
    required this.isCorrect,
    required this.showResult,
    required this.wrongWords,
    required this.isCompleted,
    required this.options,
    this.selectedIndex,
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
    );
  }

  Word? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  int get totalCount => words.length;

  ChoiceTestState copyWith({
    List<Word>? words,
    int? currentIndex,
    bool? isCorrect,
    bool? showResult,
    List<Word>? wrongWords,
    bool? isCompleted,
    List<String>? options,
    int? selectedIndex,
  }) {
    return ChoiceTestState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isCorrect: isCorrect ?? this.isCorrect,
      showResult: showResult ?? this.showResult,
      wrongWords: wrongWords ?? this.wrongWords,
      isCompleted: isCompleted ?? this.isCompleted,
      options: options ?? this.options,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

/// 选择题测试 Notifier
class ChoiceTestNotifier extends StateNotifier<ChoiceTestState> {
  ChoiceTestNotifier() : super(ChoiceTestState.initial());

  /// 加载测试单词，并生成选项
  void loadWords(List<Word> words, List<Word> allWords) {
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
    _generateOptionsForCurrent(allWords);
  }

  /// 为当前单词生成选项
  void _generateOptionsForCurrent(List<Word> allWords) {
    final current = state.currentWord;
    if (current == null) return;

    // 获取所有单词（排除自己）
    final candidates = allWords.where((w) => w.word != current.word).toList();

    // 随机选3个干扰项（如果不足3个，用剩余单词补全）
    final shuffled = List<Word>.from(candidates)..shuffle();
    final distractors = shuffled.take(3).map((w) => w.word).toList();

    // 如果干扰项不足3个，用占位符填充（实际不会发生，因为词库>3）
    while (distractors.length < 3) {
      distractors.add('???');
    }

    // 组合正确答案 + 干扰项，打乱顺序
    final options = [current.word, ...distractors]..shuffle();

    state = state.copyWith(options: options);
  }

  /// 选择答案
  void selectAnswer(int index, List<Word> allWords) {
    if (state.showResult) return;

    final current = state.currentWord;
    if (current == null) return;

    final selectedWord = state.options[index];
    final isCorrect = selectedWord == current.word;

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
  void nextWord(List<Word> allWords) {
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
      _generateOptionsForCurrent(allWords);
    }
  }

  void reset() {
    state = ChoiceTestState.initial();
  }
}

final choiceTestProvider = StateNotifierProvider<ChoiceTestNotifier, ChoiceTestState>((ref) {
  return ChoiceTestNotifier();
});