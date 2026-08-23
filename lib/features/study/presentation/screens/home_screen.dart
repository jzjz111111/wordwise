import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_provider.dart';
import 'study_screen.dart';
import '../providers/word_category_provider.dart';
import 'wrong_word_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // ====================== 全局配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _reviewColor = Color(0xFFFFB74D);
  static const Color _masteredColor = Color(0xFF81C784);
  static const Color _totalColor = Color(0xFF8A9EDB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          const StatsScreen(),
          const WrongWordScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: _cardColor,
        elevation: 0,
        indicatorColor: _accentBg,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: _secondaryText, size: 22),
            selectedIcon: Icon(Icons.home_rounded, color: _accentColor, size: 22),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: _secondaryText, size: 22),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: _accentColor, size: 22),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.error_outline, color: _secondaryText, size: 22),
            selectedIcon: Icon(Icons.error_rounded, color: _accentColor, size: 22),
            label: '错词本',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: _secondaryText, size: 22),
            selectedIcon: Icon(Icons.person_rounded, color: _accentColor, size: 22),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    final statsAsync = ref.watch(todayStatsProvider);
    final wordsAsync = ref.watch(todayWordsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'WordWise',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _accentColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '今日学习',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '坚持每一天，词汇量自然增长',
            style: TextStyle(fontSize: 14, color: _secondaryText),
          ),
          const SizedBox(height: 32),

          // 统计卡片
          statsAsync.when(
            data: (stats) => _buildStatsGrid(stats),
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
              ),
            ),
            error: (err, stack) => SizedBox(
              height: 120,
              child: Center(child: Text('加载失败: $err', style: const TextStyle(color: _secondaryText))),
            ),
          ),

          const SizedBox(height: 36),

          // 开始学习按钮
          wordsAsync.when(
            data: (words) => _buildPrimaryButton(
              label: words.isEmpty ? '今日已完成' : '开始学习 (${words.length} 个)',
              enabled: words.isNotEmpty,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyScreen(initialWords: words),
                  ),
                );
              },
            ),
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Center(child: Text('加载失败: $err', style: const TextStyle(color: _secondaryText))),
          ),

          const SizedBox(height: 16),

          // 背新词入口
          _buildOutlineButton(
            icon: Icons.add_rounded,
            label: '背新词',
            onTap: () => _showCountPicker(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.history_rounded,
            label: '待复习',
            value: stats['todayReview'] ?? 0,
            color: _reviewColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            label: '已掌握',
            value: stats['mastered'] ?? 0,
            color: _masteredColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.menu_book_rounded,
            label: '总词汇',
            value: stats['total'] ?? 0,
            color: _totalColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // 主按钮（填充样式）
  Widget _buildPrimaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) {
            if (enabled) setBtnState(() => scale = 0.96);
          },
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: enabled ? onTap : null,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: enabled ? _accentColor : _secondaryText,
                borderRadius: BorderRadius.circular(16),
                boxShadow: enabled
                    ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // 次按钮（描边样式）
  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.96),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: _accentColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCountPicker(BuildContext context, WidgetRef ref) {
    final List<int> presetCounts = List.generate(30, (index) => (index + 1) * 10);
    int selectedCount = 10;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '选择新词数量',
                style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount 个',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    width: 300,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: presetCounts.map((count) {
                          final isSelected = selectedCount == count;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCount = count;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? _accentColor : _accentBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _primaryText,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: _secondaryText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _startLearningNewWords(context, ref, selectedCount);
                  },
                  child: const Text('开始背词'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startLearningNewWords(BuildContext context, WidgetRef ref, int count) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('加载中...'),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final asyncValue = await ref.refresh(newWordsProvider(count));

      asyncValue.when(
        data: (words) {
          if (words.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('没有更多新词了！'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyScreen(initialWords: words),
            ),
          );
        },
        loading: () {},
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('加载失败: $err'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载失败: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/study_provider.dart';
// import 'study_screen.dart';
// import '../providers/word_category_provider.dart';
// import 'wrong_word_screen.dart';
// import 'stats_screen.dart';
// import 'settings_screen.dart';
// import '../../../profile/presentation/screens/profile_screen.dart';
//
// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   int _selectedIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: [
//           _buildHomePage(),           // 首页
//           const StatsScreen(),        // 统计
//           const WrongWordScreen(),    // 错词本
//           const ProfileScreen(),      // 个人中心
//         ],
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home),
//             label: '首页',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.bar_chart_outlined),
//             selectedIcon: Icon(Icons.bar_chart),
//             label: '统计',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.error_outline),
//             selectedIcon: Icon(Icons.error),
//             label: '错词本',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.person_outline),
//             selectedIcon: Icon(Icons.person),
//             label: '我的',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHomePage() {
//     final statsAsync = ref.watch(todayStatsProvider);
//     final wordsAsync = ref.watch(todayWordsProvider);
//
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               '📚 WordWise',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '今日学习',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '坚持每一天，词汇量自然增长',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             const SizedBox(height: 32),
//
//             // 统计卡片
//             statsAsync.when(
//               data: (stats) => _buildStatsGrid(stats),
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (err, stack) => Center(child: Text('加载失败: $err')),
//             ),
//
//             const SizedBox(height: 32),
//
//             // 开始学习按钮（复习入口）
//             wordsAsync.when(
//               data: (words) => SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: words.isEmpty
//                       ? null
//                       : () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => StudyScreen(
//                           initialWords: words,
//                         ),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   child: Text(
//                     words.isEmpty
//                         ? '🎉 今日已完成！'
//                         : '🚀 开始学习 (${words.length} 个)',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (err, stack) => Center(child: Text('加载失败: $err')),
//             ),
//
//             // 背新词入口（点击弹出选择器）
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => _showCountPicker(context, ref),
//                 icon: const Icon(Icons.add),
//                 label: const Text('📖 背新词'),
//                 style: ElevatedButton.styleFrom(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatsGrid(Map<String, int> stats) {
//     return Row(
//       children: [
//         _buildStatCard(
//           label: '待复习',
//           value: stats['todayReview'] ?? 0,
//           color: Colors.orange,
//         ),
//         const SizedBox(width: 16),
//         _buildStatCard(
//           label: '已掌握',
//           value: stats['mastered'] ?? 0,
//           color: Colors.green,
//         ),
//         const SizedBox(width: 16),
//         _buildStatCard(
//           label: '总词汇',
//           value: stats['total'] ?? 0,
//           color: Colors.blue,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatCard({
//     required String label,
//     required int value,
//     required Color color,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           color: color.withAlpha(26),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: color.withAlpha(78),
//           ),
//         ),
//         child: Column(
//           children: [
//             Text(
//               value.toString(),
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showCountPicker(BuildContext context, WidgetRef ref) {
//     final List<int> presetCounts = List.generate(30, (index) => (index + 1) * 10);
//     int selectedCount = 10;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('选择新词数量'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     '$selectedCount 个',
//                     style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     height: 150,
//                     child: SingleChildScrollView(
//                       child: Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: presetCounts.map((count) {
//                           final isSelected = selectedCount == count;
//                           return ChoiceChip(
//                             label: Text('$count'),
//                             selected: isSelected,
//                             onSelected: (selected) {
//                               setState(() {
//                                 selectedCount = count;
//                               });
//                             },
//                             selectedColor: Colors.blue,
//                             backgroundColor: Colors.grey[200],
//                             labelStyle: TextStyle(
//                               color: isSelected ? Colors.white : Colors.black,
//                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('取消'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     _startLearningNewWords(context, ref, selectedCount);
//                   },
//                   child: const Text('开始背词'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _startLearningNewWords(BuildContext context, WidgetRef ref, int count) async {
//     // 显示加载提示（可选）
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('加载中...'), duration: Duration(milliseconds: 500)),
//     );
//
//     try {
//       // ✅ 使用 refresh 强制刷新并等待数据返回
//       final asyncValue = await ref.refresh(newWordsProvider(count));
//
//       asyncValue.when(
//         data: (words) {
//           if (words.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('没有更多新词了！')),
//             );
//             return;
//           }
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => StudyScreen(
//                 initialWords: words,
//               ),
//             ),
//           );
//         },
//         loading: () {},
//         error: (err, stack) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('加载失败: $err')),
//           );
//         },
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('加载失败: $e')),
//       );
//     }
//   }
// }