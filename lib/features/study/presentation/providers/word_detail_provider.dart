import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/word.dart';
import '../../domain/entities/study_record.dart';
import '../../domain/repositories/word_repository.dart';
import 'study_provider.dart';  // ✅ 复用已有的 wordRepositoryProvider

final wordDetailProvider = FutureProvider.family<(Word, StudyRecord?), int>((ref, wordId) async {
  final repository = ref.watch(wordRepositoryProvider);  // ✅ 从 study_provider 引入
  return await repository.getWordDetail(wordId);
});