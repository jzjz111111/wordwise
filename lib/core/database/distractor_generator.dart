import 'dart:math';

class DistractorGenerator {
  static List<String> generate({
    required String targetWord,
    required String targetMeaning,
    required List<String> allWords,
    required List<String> allMeanings,
    int count = 3,
  }) {
    // 1. 提取词性
    final targetPos = _extractPos(targetMeaning);

    // 2. 筛选同词性候选词
    final candidates = <String>[];
    for (int i = 0; i < allWords.length; i++) {
      if (allWords[i] == targetWord) continue;
      if (_extractPos(allMeanings[i]) == targetPos) {
        candidates.add(allWords[i]);
      }
    }

    // 3. 候选池（同词性优先，不足则放宽）
    final pool = candidates.length >= count * 2
        ? candidates
        : allWords.where((w) => w != targetWord).toList();

    // 4. 按相似度排序
    pool.sort((a, b) {
      final scoreA = _similarityScore(targetWord, a);
      final scoreB = _similarityScore(targetWord, b);
      return scoreB.compareTo(scoreA);
    });

    return pool.take(count).toList();
  }

  static String _extractPos(String meaning) {
    final match = RegExp(r'^[a-z]+\.').firstMatch(meaning.trim());
    if (match != null) return match.group(0)!;
    if (meaning.contains('动词')) return 'v.';
    if (meaning.contains('名词')) return 'n.';
    if (meaning.contains('形容词')) return 'adj.';
    if (meaning.contains('副词')) return 'adv.';
    return 'n.';
  }

  static double _similarityScore(String word1, String word2) {
    int commonPrefix = 0;
    for (int i = 0; i < min(word1.length, word2.length); i++) {
      if (word1[i] == word2[i]) {
        commonPrefix++;
      } else {
        break;
      }
    }
    final lengthDiff = (word1.length - word2.length).abs();
    final lengthScore = 1 - (lengthDiff / max(word1.length, word2.length));
    return (commonPrefix / max(word1.length, word2.length)) * 0.7 +
        lengthScore * 0.3;
  }

  static int min(int a, int b) => a < b ? a : b;
  static int max(int a, int b) => a > b ? a : b;
}