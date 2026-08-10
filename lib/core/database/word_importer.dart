import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WordImporter {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 从 assets 加载 NDJSON 词库并导入数据库
  // static Future<int> importFromAssets({
  //   required String assetPath,
  //   required String category,
  //   bool clearExisting = false,
  // }) async {
  //   final db = await _dbHelper.database;
  //
  //   if (clearExisting) {
  //     await db.delete('study_records',
  //         where: 'word_id IN (SELECT id FROM words WHERE category = ?)',
  //         whereArgs: [category]);
  //     await db.delete('words', where: 'category = ?', whereArgs: [category]);
  //   }
  //
  //   // 读取整个文件
  //   final jsonString = await rootBundle.loadString(assetPath);
  //
  //   // ✅ 按行分割，逐行解析
  //   final lines = jsonString.split('\n');
  //   int count = 0;
  //
  //   for (var line in lines) {
  //     line = line.trim();
  //     if (line.isEmpty) continue;
  //
  //     try {
  //       final item = jsonDecode(line) as Map<String, dynamic>;
  //
  //       // 1. 获取 headWord（单词本身）
  //       final headWord = item['headWord']?.toString() ?? '';
  //       if (headWord.isEmpty) continue;
  //
  //       // 2. 获取 content.word
  //       final content = item['content'] as Map<String, dynamic>?;
  //       final wordData = content?['word'] as Map<String, dynamic>?;
  //       if (wordData == null) continue;
  //
  //       // 3. 获取 wordHead
  //       final word = wordData['wordHead']?.toString() ?? headWord;
  //
  //       // 4. 获取音标
  //       final usphone = wordData['usphone']?.toString() ?? '';
  //       final ukphone = wordData['ukphone']?.toString() ?? '';
  //
  //       // 5. 获取中文释义（从 trans 数组中取第一个）
  //       String meaning = '';
  //       final transList = wordData['trans'] as List?;
  //       if (transList != null && transList.isNotEmpty) {
  //         final firstTrans = transList.first as Map<String, dynamic>?;
  //         if (firstTrans != null) {
  //           meaning = firstTrans['tranCn']?.toString() ?? '';
  //         }
  //       }
  //
  //       // 6. 获取例句（从 sentence.sentences 中取第一个）
  //       String example = '';
  //       final sentenceData = wordData['sentence'] as Map<String, dynamic>?;
  //       if (sentenceData != null) {
  //         final sentences = sentenceData['sentences'] as List?;
  //         if (sentences != null && sentences.isNotEmpty) {
  //           final firstSentence = sentences.first as Map<String, dynamic>?;
  //           if (firstSentence != null) {
  //             final sContent = firstSentence['sContent']?.toString() ?? '';
  //             final sCn = firstSentence['sCn']?.toString() ?? '';
  //             if (sContent.isNotEmpty) {
  //               example = sCn.isNotEmpty ? '$sContent|$sCn' : sContent;
  //             }
  //           }
  //         }
  //       }
  //
  //       // 7. 检查是否已存在
  //       final existing = await db.query(
  //         'words',
  //         where: 'word = ? AND category = ?',
  //         whereArgs: [word, category],
  //       );
  //
  //       if (existing.isNotEmpty) continue;
  //
  //       // 8. 插入单词
  //       final wordId = await db.insert('words', {
  //         'word': word,
  //         'meaning': meaning,
  //         'phonetic_uk': ukphone,
  //         'phonetic_us': usphone,
  //         'example': example,
  //         'category': category,
  //       });
  //
  //       count++;
  //
  //       // 每 100 个打印一次进度
  //       if (count % 100 == 0) {
  //         print('✅ 已导入 $count 个单词');
  //       }
  //
  //     } catch (e) {
  //       print('⚠️ 跳过一行: $e');
  //       continue;
  //     }
  //   }
  //   return count;
  // }
  static Future<int> importFromAssets({
    required String assetPath,
    required String category,
    bool clearExisting = false,
  }) async {
    final db = await _dbHelper.database;

    if (clearExisting) {
      await db.delete('words', where: 'category = ?', whereArgs: [category]);
    }

    final jsonString = await rootBundle.loadString(assetPath);
    final lines = jsonString.split('\n');
    int count = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        final item = jsonDecode(line) as Map<String, dynamic>;

        final headWord = item['headWord']?.toString() ?? '';
        if (headWord.isEmpty) continue;

        final content = item['content'] as Map<String, dynamic>?;
        if (content == null) continue;

        final wordData = content['word'] as Map<String, dynamic>?;
        if (wordData == null) continue;

        // 获取单词
        final word = wordData['wordHead']?.toString() ?? headWord;

        // 获取 wordContent（可能嵌套在 content 字段里）
        final wordContent = wordData['content'] as Map<String, dynamic>?;

        // ✅ 音标：优先从 wordContent 取，找不到再从 wordData 取
        final usphone = wordContent?['usphone']?.toString() ??
            wordData['usphone']?.toString() ?? '';

        final ukphone = wordContent?['ukphone']?.toString() ??
            wordData['ukphone']?.toString() ?? '';

        // ✅ 释义
        String meaning = '';
        final transList = wordContent?['trans'] as List? ?? wordData['trans'] as List?;
        if (transList != null && transList.isNotEmpty) {
          final firstTrans = transList.first as Map<String, dynamic>?;
          if (firstTrans != null) {
            meaning = firstTrans['tranCn']?.toString() ?? '';
          }
        }

        // ✅ 例句
        String example = '';
        final sentenceData = wordContent?['sentence'] as Map<String, dynamic>? ??
            wordData['sentence'] as Map<String, dynamic>?;
        if (sentenceData != null) {
          final sentences = sentenceData['sentences'] as List?;
          if (sentences != null && sentences.isNotEmpty) {
            final firstSentence = sentences.first as Map<String, dynamic>?;
            if (firstSentence != null) {
              final sContent = firstSentence['sContent']?.toString() ?? '';
              final sCn = firstSentence['sCn']?.toString() ?? '';
              example = sCn.isNotEmpty ? '$sContent|$sCn' : sContent;
            }
          }
        }

        // 检查是否已存在
        final existing = await db.query(
          'words',
          where: 'word = ? AND category = ?',
          whereArgs: [word, category],
        );
        if (existing.isNotEmpty) continue;

        await db.insert('words', {
          'word': word,
          'meaning': meaning,
          'phonetic_uk': ukphone,
          'phonetic_us': usphone,
          'example': example,
          'category': category,
        });
        count++;

        if (count % 100 == 0) {
          print('✅ 已导入 $count 个单词');
        }
      } catch (e) {
        print('⚠️ 跳过一行: $e');
        continue;
      }
    }
    return count;
  }

  /// 导入所有词库
  static Future<Map<String, int>> importAll() async {
    final results = <String, int>{};

    final categories = [
      {'path': 'assets/dicts/CET4.json', 'category': 'cet4'},
      {'path': 'assets/dicts/CET6.json', 'category': 'cet6'},
      {'path': 'assets/dicts/KaoYan.json', 'category': 'ky'},
    ];

    for (var item in categories) {
      try {
        final count = await importFromAssets(
          assetPath: item['path']!,
          category: item['category']!,
          clearExisting: true,
        );
        results[item['category']!] = count;
        print('✅ 导入 ${item['category']} 完成: $count 个单词');
      } catch (e) {
        results[item['category']!] = -1;
        print('❌ 导入 ${item['category']} 失败: $e');
      }
    }
    return results;
  }
}