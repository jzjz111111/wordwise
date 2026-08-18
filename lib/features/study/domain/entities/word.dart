import 'dart:convert';

/// 单词实体类
/// 对应数据库中的 words 表
class Word {
  final int? id;
  final String word;
  final String meaning;
  final String? phoneticUk;
  final String? phoneticUs;
  final String? example;
  final String category;
  final List<String>? distractors;
  // final List<Map<String, dynamic>>? exam;

  Word({
    this.id,
    required this.word,
    required this.meaning,
    this.phoneticUk,
    this.phoneticUs,
    this.example,
    this.category='cet4',
    this.distractors,
    // this.exam,
  });

  /// 从 Map 创建 Word 对象（数据库查询结果 → 对象）
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      phoneticUk: map['phonetic_uk'] as String?,
      phoneticUs: map['phonetic_us'] as String?,
      example: map['example'] as String?,
      category: map['category'] as String,
      distractors: map['distractors'] != null
          ? List<String>.from(jsonDecode(map['distractors'] as String))
          : null,
      // exam: map['exam'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['exam'] as String)) : null,
    );
  }

  /// 把 Word 对象转换成 Map（插入数据库时用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'phonetic_uk': phoneticUk,
      'phonetic_us': phoneticUs,
      'example': example,
      'category':category,
      'distractors': distractors != null ? jsonEncode(distractors) : null,
      // 'exam': exam != null ? jsonEncode(exam) : null,
    };
  }
}