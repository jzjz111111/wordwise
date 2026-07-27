import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/word.dart';
import '../../domain/entities/study_record.dart';
import '../../domain/repositories/word_repository.dart';
import '../../data/repositories/word_repository_impl.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepositoryImpl();
});

final wordDetailProvider = FutureProvider.family<(Word, StudyRecord?), int>((ref, wordId) async {
  final repository = ref.watch(wordRepositoryProvider);
  return await repository.getWordDetail(wordId);
});