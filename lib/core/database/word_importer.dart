import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'distractor_generator.dart';

class WordImporter {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
    final lines = LineSplitter.split(jsonString);

    // ============================================================
    // 第一遍：收集所有单词和释义
    // ============================================================
    final allWords = <String>[];
    final allMeanings = <String>[];
    final parsedItems = <Map<String, dynamic>>[];

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

        final word = wordData['wordHead']?.toString() ?? headWord;
        final wordContent = wordData['content'] as Map<String, dynamic>?;

        // 提取释义
        String meaning = '';
        final transList = wordContent?['trans'] as List?;
        if (transList != null && transList.isNotEmpty) {
          meaning = transList.map((t) {
            final tMap = t as Map<String, dynamic>;
            final pos = tMap['pos']?.toString() ?? '';
            final tranCn = tMap['tranCn']?.toString().trim() ?? '';
            return pos.isNotEmpty ? '$pos. $tranCn' : tranCn;
          }).join('；');
        }

        // ✅ 收集到列表中
        allWords.add(word);
        allMeanings.add(meaning);
        parsedItems.add(item);

      } catch (e) {
        print('⚠️ 跳过一行: $e');
        continue;
      }
    }

    print('📚 共收集 ${allWords.length} 个单词');

    // ============================================================
    // 第二遍：生成干扰项并插入数据库
    // ============================================================
    final batch = db.batch();
    int count = 0;

    for (var item in parsedItems) {
      try {
        final headWord = item['headWord']?.toString() ?? '';
        final content = item['content'] as Map<String, dynamic>?;
        final wordData = content?['word'] as Map<String, dynamic>?;
        if (wordData == null) continue;

        final word = wordData['wordHead']?.toString() ?? headWord;
        final wordContent = wordData['content'] as Map<String, dynamic>?;

        // 音标
        final usphone = wordContent?['usphone']?.toString() ?? '';
        final ukphone = wordContent?['ukphone']?.toString() ?? '';

        // 释义
        String meaning = '';
        final transList = wordContent?['trans'] as List?;
        if (transList != null && transList.isNotEmpty) {
          meaning = transList.map((t) {
            final tMap = t as Map<String, dynamic>;
            final pos = tMap['pos']?.toString() ?? '';
            final tranCn = tMap['tranCn']?.toString().trim() ?? '';
            return pos.isNotEmpty ? '$pos. $tranCn' : tranCn;
          }).join('；');
        }

        // 例句
        String example = '';
        final sentenceData = wordContent?['sentence'] as Map<String, dynamic>?;
        if (sentenceData != null) {
          final sentences = sentenceData['sentences'] as List?;
          if (sentences != null && sentences.isNotEmpty) {
            final firstSentence = sentences.first as Map<String, dynamic>;
            final sContent = firstSentence['sContent']?.toString() ?? '';
            final sCn = firstSentence['sCn']?.toString() ?? '';
            example = sCn.isNotEmpty ? '$sContent|$sCn' : sContent;
          }
        }

        // ✅ 生成干扰项（现在 allWords 和 allMeanings 已经有数据了）
        final distractors = DistractorGenerator.generate(
          targetWord: word,
          targetMeaning: meaning,
          allWords: allWords,
          allMeanings: allMeanings,
        );

        batch.insert('words', {
          'word': word,
          'meaning': meaning,
          'phonetic_uk': ukphone,
          'phonetic_us': usphone,
          'example': example,
          'category': category,
          'distractors': jsonEncode(distractors),
        });
        count++;

        if (count % 100 == 0) {
          print('✅ 已处理 $count 个单词');
        }
      } catch (e) {
        print('⚠️ 跳过一行: $e');
        continue;
      }
    }

    await batch.commit(noResult: true);
    print('✅ 导入完成，共 $count 个单词');
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