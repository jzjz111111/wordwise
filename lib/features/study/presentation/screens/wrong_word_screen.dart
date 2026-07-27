import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wrong_word_provider.dart';
import 'word_detail_screen.dart';

class WrongWordScreen extends ConsumerStatefulWidget {
  const WrongWordScreen({super.key});

  @override
  ConsumerState<WrongWordScreen> createState() => _WrongWordScreenState();
}

class _WrongWordScreenState extends ConsumerState<WrongWordScreen> {
  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wrongWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📕 错词本'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(wrongWordsProvider);  // ← 手动刷新
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(wrongWordsProvider);  // ← 下拉刷新
          await Future.delayed(const Duration(milliseconds: 100));
        },
        child: wordsAsync.when(
          data: (words) {
            if (words.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('🎉 暂无错词，继续加油！'),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return ListTile(
                  title: Text(word.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(word.meaning),
                  leading: const Icon(Icons.error, color: Colors.red),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      final repo = ref.read(wrongWordRepositoryProvider);
                      repo.removeWrongWord(word.id!);
                      ref.invalidate(wrongWordsProvider);  // ← 删除后刷新
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已移除: ${word.word}')),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordDetailScreen(wordId: word.id!),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('加载失败: $err')),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空错词本'),
        content: const Text('确定要清空所有错词吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final repo = ref.read(wrongWordRepositoryProvider);
              repo.clearWrongWords();
              ref.invalidate(wrongWordsProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空错词本')),
              );
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}