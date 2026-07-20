import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/wrong_word_repository.dart';
import '../../data/repositories/wrong_word_repository_impl.dart';

final wrongWordRepositoryProvider = Provider<WrongWordRepository>((ref) {
  return WrongWordRepositoryImpl();
});
/// 拼写测试状态
class SpellTestState {
  final List<Word> words;
  final int currentIndex;
  final String userInput;
  final bool isCorrect;
  final bool showResult;
  final List<Word> wrongWords;
  final bool isCompleted;

  SpellTestState({
    required this.words,
    required this.currentIndex,
    required this.userInput,
    required this.isCorrect,
    required this.showResult,
    required this.wrongWords,
    required this.isCompleted,
  });

  factory SpellTestState.initial() {
    return SpellTestState(
      words: [],
      currentIndex: 0,
      userInput: '',
      isCorrect: false,
      showResult: false,
      wrongWords: [],
      isCompleted: false,
    );
  }

  Word? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  int get totalCount => words.length;

  SpellTestState copyWith({
    List<Word>? words,
    int? currentIndex,
    String? userInput,
    bool? isCorrect,
    bool? showResult,
    List<Word>? wrongWords,
    bool? isCompleted,
  }) {
    return SpellTestState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      userInput: userInput ?? this.userInput,
      isCorrect: isCorrect ?? this.isCorrect,
      showResult: showResult ?? this.showResult,
      wrongWords: wrongWords ?? this.wrongWords,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 拼写测试 Notifier
class SpellTestNotifier extends StateNotifier<SpellTestState> {
  final Ref ref;
  SpellTestNotifier(this.ref) : super(SpellTestState.initial());

  void loadWords(List<Word> words) {
    if (words.isEmpty) {
      state = state.copyWith(isCompleted: true, words: []);
      return;
    }
    state = state.copyWith(
      words: words,
      currentIndex: 0,
      userInput: '',
      isCorrect: false,
      showResult: false,
      wrongWords: [],
      isCompleted: false,
    );
  }

  void updateInput(String value) {
    state = state.copyWith(userInput: value);
  }

  Future<void> submitAnswer() async {  // ← 加了 async
    if (state.currentWord == null) return;
    final word = state.currentWord!;
    final isCorrect = state.userInput.trim().toLowerCase() == word.word.toLowerCase();

    // 记录错词到数据库
    if (!isCorrect) {
      final wrongWordRepo = ref.read(wrongWordRepositoryProvider);
      await wrongWordRepo.addWrongWord(word.id!);
    }

    state = state.copyWith(
      isCorrect: isCorrect,
      showResult: true,
      wrongWords: isCorrect
          ? state.wrongWords
          : [...state.wrongWords, word],
    );
  }

  void nextWord() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.words.length) {
      state = state.copyWith(
        isCompleted: true,
        currentIndex: nextIndex,
        userInput: '',
        showResult: false,
      );
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        userInput: '',
        isCorrect: false,
        showResult: false,
      );
    }
  }

  void reset() {
    state = SpellTestState.initial();
  }
}

final spellTestProvider = StateNotifierProvider<SpellTestNotifier, SpellTestState>((ref) {
  return SpellTestNotifier(ref);
});