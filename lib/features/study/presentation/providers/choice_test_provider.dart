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

  ChoiceTestState copyWith({
    List<Word>? words,
    int? currentIndex,
    bool? isCorrect,
    bool? showResult,
    List<Word>? wrongWords,
    bool? isCompleted,
    List<String>? options,
    int? selectedIndex,
    int? correctIndex,
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
      correctIndex: correctIndex ?? this.correctIndex,
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
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../domain/entities/word.dart';
// import 'dart:math';
//
// /// 选择题测试状态
// class ChoiceTestState {
//   final List<Word> words;
//   final int currentIndex;
//   final bool isCorrect;
//   final bool showResult;
//   final List<Word> wrongWords;
//   final bool isCompleted;
//   final List<String> options;        // 当前题目的四个选项
//   final int? selectedIndex;          // 用户选择的选项索引
//   final int? correctIndex;
//
//   ChoiceTestState({
//     required this.words,
//     required this.currentIndex,
//     required this.isCorrect,
//     required this.showResult,
//     required this.wrongWords,
//     required this.isCompleted,
//     required this.options,
//     this.selectedIndex,
//     this.correctIndex,
//   });
//
//   factory ChoiceTestState.initial() {
//     return ChoiceTestState(
//       words: [],
//       currentIndex: 0,
//       isCorrect: false,
//       showResult: false,
//       wrongWords: [],
//       isCompleted: false,
//       options: [],
//       selectedIndex: null,
//       correctIndex: null,
//     );
//   }
//
//   Word? get currentWord =>
//       currentIndex < words.length ? words[currentIndex] : null;
//
//   int get totalCount => words.length;
//
//   ChoiceTestState copyWith({
//     List<Word>? words,
//     int? currentIndex,
//     bool? isCorrect,
//     bool? showResult,
//     List<Word>? wrongWords,
//     bool? isCompleted,
//     List<String>? options,
//     int? selectedIndex,
//     int? correctIndex,
//   }) {
//     return ChoiceTestState(
//       words: words ?? this.words,
//       currentIndex: currentIndex ?? this.currentIndex,
//       isCorrect: isCorrect ?? this.isCorrect,
//       showResult: showResult ?? this.showResult,
//       wrongWords: wrongWords ?? this.wrongWords,
//       isCompleted: isCompleted ?? this.isCompleted,
//       options: options ?? this.options,
//       selectedIndex: selectedIndex ?? this.selectedIndex,
//       correctIndex: correctIndex ?? this.correctIndex,
//     );
//   }
// }
//
// /// 选择题测试 Notifier
// class ChoiceTestNotifier extends StateNotifier<ChoiceTestState> {
//   ChoiceTestNotifier() : super(ChoiceTestState.initial());
//
//   /// 加载测试单词，并生成选项
//   void loadWords(List<Word> words, List<Word> allWords) {
//     if (words.isEmpty) {
//       state = state.copyWith(isCompleted: true, words: []);
//       return;
//     }
//     state = state.copyWith(
//       words: words,
//       currentIndex: 0,
//       isCorrect: false,
//       showResult: false,
//       wrongWords: [],
//       isCompleted: false,
//       options: [],
//       selectedIndex: null,
//     );
//     _generateOptionsForCurrent(allWords);
//   }
//
//   /// 为当前单词生成选项
//   void _generateOptionsForCurrent(List<Word> allWords) {
//     final current = state.currentWord;
//     if (current == null) return;
//
//     List<String> options;
//
//     if (current.distractors != null && current.distractors!.length >= 3) {
//       options = [current.word, ...current.distractors!]..shuffle();
//     } else {
//       options = _generateRealTimeDistractors(current, allWords);
//     }
//
//     state = state.copyWith(
//       options: options,
//       correctIndex: options.indexOf(current.word),
//     );
//   }
//
//   List<String> _generateRealTimeDistractors(Word current, List<Word> allWords) {
//     final candidates = allWords
//         .where((w) => w.word != current.word)
//         .toList();
//
//     candidates.sort((a, b) {
//       final scoreA = _similarityScore(current.word, a.word);
//       final scoreB = _similarityScore(current.word, b.word);
//       return scoreB.compareTo(scoreA);
//     });
//
//     return candidates.take(3).map((w) => w.word).toList();
//   }
//
//   double _similarityScore(String word1, String word2) {
//     int common = 0;
//     for (int i = 0; i < min(word1.length, word2.length); i++) {
//       if (word1[i] == word2[i]) common++;
//       else break;
//     }
//     return common / max(word1.length, word2.length);
//   }
//   // void _generateOptionsForCurrent(List<Word> allWords) {
//   //   final current = state.currentWord;
//   //   if (current == null) return;
//   //
//   //   // 获取所有单词（排除自己）
//   //   final candidates = allWords.where((w) => w.word != current.word).toList();
//   //
//   //   // 随机选3个干扰项（如果不足3个，用剩余单词补全）
//   //   final shuffled = List<Word>.from(candidates)..shuffle();
//   //   final distractors = shuffled.take(3).map((w) => w.word).toList();
//   //
//   //   // 如果干扰项不足3个，用占位符填充（实际不会发生，因为词库>3）
//   //   while (distractors.length < 3) {
//   //     distractors.add('???');
//   //   }
//   //
//   //   // 组合正确答案 + 干扰项，打乱顺序
//   //   final options = [current.word, ...distractors]..shuffle();
//   //
//   //   state = state.copyWith(options: options);
//   // }
//
//   /// 选择答案
//   void selectAnswer(int index, List<Word> allWords) {
//     if (state.showResult) return;
//
//     final current = state.currentWord;
//     if (current == null) return;
//
//     final selectedWord = state.options[index];
//     final isCorrect = selectedWord == current.word;
//
//     state = state.copyWith(
//       selectedIndex: index,
//       isCorrect: isCorrect,
//       showResult: true,
//       wrongWords: isCorrect
//           ? state.wrongWords
//           : [...state.wrongWords, current],
//     );
//   }
//
//   /// 下一个单词
//   void nextWord(List<Word> allWords) {
//     final nextIndex = state.currentIndex + 1;
//     if (nextIndex >= state.words.length) {
//       state = state.copyWith(
//         isCompleted: true,
//         currentIndex: nextIndex,
//         showResult: false,
//       );
//     } else {
//       state = state.copyWith(
//         currentIndex: nextIndex,
//         isCorrect: false,
//         showResult: false,
//         selectedIndex: null,
//         options: [],
//       );
//       _generateOptionsForCurrent(allWords);
//     }
//   }
//
//   void reset() {
//     state = ChoiceTestState.initial();
//   }
// }
//
// final choiceTestProvider = StateNotifierProvider<ChoiceTestNotifier, ChoiceTestState>((ref) {
//   return ChoiceTestNotifier();
// });