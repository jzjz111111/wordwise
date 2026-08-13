import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/study_provider.dart';
import 'study_screen.dart';
import '../providers/word_category_provider.dart';
import 'wrong_word_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _newWordCountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _newWordCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(todayStatsProvider);
    final wordsAsync = ref.watch(todayWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 WordWise'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日学习',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '坚持每一天，词汇量自然增长',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 单词库选择
            Consumer(
              builder: (context, ref, child) {
                final categories = ref.watch(categoriesProvider);
                final currentCategory = ref.watch(currentCategoryProvider);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = cat['id'] == currentCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${cat['icon']} ${cat['name']}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(currentCategoryProvider.notifier).state = cat['id']!;
                              ref.invalidate(todayWordsProvider);
                              ref.invalidate(todayStatsProvider);
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // 统计卡片
            statsAsync.when(
              data: (stats) => _buildStatsGrid(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),

            const SizedBox(height: 32),

            // 开始学习按钮（复习入口）
            wordsAsync.when(
              data: (words) => SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: words.isEmpty
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyScreen(
                          initialWords: words,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    words.isEmpty
                        ? '🎉 今日已完成！'
                        : '🚀 开始学习 (${words.length} 个)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),

            // 背新词入口（点两次稳定版）
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newWordCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '新词数量',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      final count = int.tryParse(_newWordCountController.text) ?? 10;
                      if (count <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效数量')),
                        );
                        return;
                      }

                      final newWordsAsync = ref.read(newWordsProvider(count));
                      newWordsAsync.when(
                        data: (words) {
                          if (words.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('没有更多新词了！')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudyScreen(
                                initialWords: words,
                              ),
                            ),
                          );
                        },
                        loading: () {
                          // 第一次点击触发加载，第二次点击数据已缓存，直接跳转
                        },
                        error: (err, stack) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('加载失败: $err')),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('📖 背新词'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WrongWordScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.error_outline),
                label: const Text('📕 错词本'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('📊 学习统计'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return Row(
      children: [
        _buildStatCard(
          label: '待复习',
          value: stats['todayReview'] ?? 0,
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          label: '已掌握',
          value: stats['mastered'] ?? 0,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          label: '总词汇',
          value: stats['total'] ?? 0,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(78),
          ),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}