import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/word_detail_provider.dart';
import '../../domain/entities/study_record.dart';
import '../../domain/entities/word.dart';
import 'study_screen.dart';

class WordDetailScreen extends ConsumerWidget {
  final int wordId;

  const WordDetailScreen({
    super.key,
    required this.wordId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(wordDetailProvider(wordId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 单词详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              // 发音功能
              detailAsync.whenData((detail) {
                final tts = FlutterTts();
                tts.speak(detail.$1.word);
              });
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (data) => _buildContent(context, data.$1, data.$2),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(wordDetailProvider(wordId));
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      Word word,
      StudyRecord? record,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 单词 + 音标
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (word.phoneticUk != null || word.phoneticUs != null) ...[
                      if (word.phoneticUk != null)
                        Text(
                          '英 ${word.phoneticUk}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (word.phoneticUs != null)
                        Text(
                          '美 ${word.phoneticUs}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final tts = FlutterTts();
                  tts.speak(word.word);
                },
                icon: const Icon(Icons.volume_up, size: 32),
                color: Colors.blue,
              ),
            ],
          ),

          const Divider(height: 32),

          // 释义
          const Text(
            '📝 释义',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              word.meaning,
              style: const TextStyle(fontSize: 18),
            ),
          ),

          const SizedBox(height: 24),

          // 例句
          if (word.example != null && word.example!.isNotEmpty) ...[
            const Text(
              '💬 例句',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Text(
                word.example!,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 学习状态
          if (record != null) ...[
            const Text(
              '📊 学习状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusCard(record),
            const SizedBox(height: 24),
          ],

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 跳转到学习界面，只复习这一个词
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyScreen(
                          initialWords: [word],  // 传入单个单词列表
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('复习这个词'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(StudyRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            '🔄',
            '${record.reviewCount}次',
            '复习次数',
          ),
          _buildStatusItem(
            '📊',
            '${record.masteryLevel}/5',
            '掌握程度',
          ),
          _buildStatusItem(
            '📅',
            _formatDate(record.nextReviewDate),
            '下次复习',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return '今天';
    if (target == today.add(const Duration(days: 1))) return '明天';
    if (target == today.subtract(const Duration(days: 1))) return '昨天';

    return '${date.month}/${date.day}';
  }
}