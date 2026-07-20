import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/wrong_word_repository.dart';
import '../../data/repositories/wrong_word_repository_impl.dart';
import '../../domain/entities/word.dart';

final wrongWordRepositoryProvider = Provider<WrongWordRepository>((ref) {
  return WrongWordRepositoryImpl();
});

final wrongWordsProvider = FutureProvider<List<Word>>((ref) async {
  final repository = ref.watch(wrongWordRepositoryProvider);
  return await repository.getAllWrongWords();
});