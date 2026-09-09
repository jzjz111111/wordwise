import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/screens/word_library_screen.dart';
import '../../domain/entities/daily_sentence.dart';
import '../../domain/entities/study_stats.dart';
import '../../domain/entities/word.dart';
import '../providers/study_provider.dart';
import 'favorite_word_screen.dart';
import 'new_word_screen.dart';
import 'study_screen.dart';
import '../providers/word_category_provider.dart';
import 'wrong_word_screen.dart';
import 'stats_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/study_stats_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // ====================== 与统计页完全统一配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);

  // 和stats_screen掌握程度色系保持一致
  static const Color _basicColor = Color(0xFFFFB74D);
  static const Color _intermediateColor = Color(0xFF8A9EDB);
  static const Color _advancedColor = Color(0xFF81C784);

  /// 主渐变，对齐统计页主题蓝色调
  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [Color(0xFF8A9EDB), Color(0xFF7389D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          const WrongWordScreen(),
          const StatsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            ref.invalidate(dailyStudyStatsProvider);
            ref.invalidate(masteryDistributionProvider);
            ref.invalidate(totalStudyStatsProvider);
          }
          // 切到个人页（第4个标签，索引为3）时，自动刷新总统计数据
          if (index == 3) {
            ref.invalidate(totalStudyStatsProvider);
          }
        },
        backgroundColor: _cardColor,
        elevation: 0,
        height: 72,
        indicatorColor: _accentBg,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: _secondaryText, size: 24),
            selectedIcon: Icon(Icons.home_rounded, color: _accentColor, size: 24),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.error_outline, color: _secondaryText, size: 24),
            selectedIcon: Icon(Icons.error_rounded, color: _accentColor, size: 24),
            label: '错词本',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: _secondaryText, size: 24),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: _accentColor, size: 24),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: _secondaryText, size: 24),
            selectedIcon: Icon(Icons.person_rounded, color: _accentColor, size: 24),
            label: '我的',
          ),
        ],
      ),
    );
  }

  // ====================== 主页主体 ======================
  Widget _buildHomePage() {
    final statsAsync = ref.watch(todayStatsProvider);
    final wordsAsync = ref.watch(todayWordsProvider);
    final category = ref.watch(currentCategoryProvider);
    final totalStatsAsync = ref.watch(totalStudyStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(totalStatsAsync),
          const SizedBox(height: 10),
          _buildDailySentenceCard(),
          const SizedBox(height: 10),
          _buildCategoryChip(category, statsAsync), // 传入statsAsync用于判断状态
          const SizedBox(height: 24),

          // ========== 核心：双状态分支 ==========
          statsAsync.when(
            data: (stats) {
              final total = stats['total'] ?? 0;
              if (total == 0) {
                // 未导入词库：显示空状态引导
                return _buildEmptyLibraryState();
              } else {
                // 已导入词库：正常渲染全部内容
                return Column(
                  children: [
                    _buildMainProgressCard(stats),
                    const SizedBox(height: 20),
                    _buildStatsOverview(wordsAsync, statsAsync),
                    const SizedBox(height: 28),
                    _buildMainActionButtons(wordsAsync),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                  ],
                );
              }
            },
            loading: () => _buildLoadingCard(height: 280),
            error: (err, stack) => _buildErrorCard('加载失败: $err'),
          ),
        ],
      ),
    );
  }
  // Widget _buildHomePage() {
  //   final statsAsync = ref.watch(todayStatsProvider);
  //   final wordsAsync = ref.watch(todayWordsProvider);
  //   final category = ref.watch(currentCategoryProvider);
  //   final totalStatsAsync = ref.watch(totalStudyStatsProvider);
  //
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // 1. 顶部问候栏（使用真实连续天数）
  //         _buildTopHeader(totalStatsAsync),
  //         const SizedBox(height: 10),
  //
  //         //每日例句
  //         _buildDailySentenceCard(),
  //         const SizedBox(height: 10),
  //
  //         // 2. 词库切换胶囊
  //         _buildCategoryChip(category),
  //         const SizedBox(height: 24),
  //
  //         // 3. 核心进度大卡片
  //         statsAsync.when(
  //           data: (stats) => _buildMainProgressCard(stats),
  //           loading: () => _buildLoadingCard(height: 280),
  //           error: (err, stack) => _buildErrorCard('加载失败: $err'),
  //         ),
  //         const SizedBox(height: 20),
  //
  //         // 4. 数据概览卡片组
  //         _buildStatsOverview(wordsAsync, statsAsync),
  //         const SizedBox(height: 28),
  //
  //         // 5. 主操作按钮区
  //         _buildMainActionButtons(wordsAsync),
  //         const SizedBox(height: 32),
  //
  //         // 6. 快捷功能入口
  //         _buildQuickActions(),
  //       ],
  //     ),
  //   );
  // }

  // ========== 1. 顶部标题栏：接入真实连续天数数据源 ==========
  Widget _buildTopHeader(AsyncValue<TotalStudyStats> totalStatsAsync) {
    final now = DateTime.now();
    final weekDay = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][now.weekday - 1];
    final dateStr = '${now.month}月${now.day}日 $weekDay';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WordWise',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _accentColor,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr,
              style: const TextStyle(fontSize: 13, color: _secondaryText),
            ),
            // 连续打卡徽章，从totalStudyStatsProvider取真实consecutiveDays
            totalStatsAsync.when(
              data: (totalData) {
                final streakDays = totalData.consecutiveDays;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _basicColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 14, color: _basicColor),
                      const SizedBox(width: 4),
                      Text(
                        '连续 $streakDays 天',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _basicColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(width:80,height:24,child:CircularProgressIndicator(strokeWidth:2)),
              error: (_,__) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  // ========== 2. 词库切换胶囊 ==========
  Widget _buildCategoryChip(String category, AsyncValue<Map<String, int>> statsAsync) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WordLibraryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _accentBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 16, color: _accentColor),
            const SizedBox(width: 6),
            statsAsync.when(
              data: (stats) {
                final total = stats['total'] ?? 0;
                return Text(
                  total == 0 ? '请导入词库' : _getCategoryName(category),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _accentColor,
                  ),
                );
              },
              loading: () => Text(
                '加载中...',
                style: TextStyle(fontSize: 13, color: _accentColor),
              ),
              error: (_, __) => Text(
                '请导入词库',
                style: TextStyle(fontSize: 13, color: _accentColor),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: _accentColor),
          ],
        ),
      ),
    );
  }

  // ========== 3. 核心进度大卡片 ==========
  Widget _buildMainProgressCard(Map<String, int> stats) {
    final total = stats['total'] ?? 1;
    final reviewed = stats['reviewed'] ?? 0;
    final progress = total > 0 ? reviewed / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '词库背诵进度',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景环
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    color: Colors.transparent,
                  ),
                ),
                // 进度环
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    color: Colors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // 中心文字
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$reviewed / $total',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 底部数据行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem('已背诵', '$reviewed', Colors.white),
              Container(width: 1, height: 32, color: Colors.white24),
              _buildProgressItem('总词汇', '$total', Colors.white),
              Container(width: 1, height: 32, color: Colors.white24),
              _buildProgressItem('剩余', '${total - reviewed}', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  // ========== 4. 数据概览卡片组 ==========
  Widget _buildStatsOverview(AsyncValue<List> wordsAsync, AsyncValue<Map<String, int>> statsAsync) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.history_rounded,
            label: '待复习',
            color: _basicColor,
            asyncValue: wordsAsync,
            valueBuilder: (data) => '${data.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.auto_awesome_rounded,
            label: '今日新词',
            color: _accentColor,
            asyncValue: statsAsync,
            valueBuilder: (data) => '${data['newToday'] ?? 0}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.verified_rounded,
            label: '已掌握',
            color: _advancedColor,
            asyncValue: statsAsync,
            valueBuilder: (data) => '${data['mastered'] ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard<T>({
    required IconData icon,
    required String label,
    required Color color,
    required AsyncValue<T> asyncValue,
    required String Function(T data) valueBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          asyncValue.when(
            data: (data) => Text(
              valueBuilder(data),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color:_accentColor,strokeWidth: 2),
            ),
            error: (_, __) => const Text('--', style: TextStyle(color: _secondaryText)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  // ========== 5. 主操作按钮区 ==========
  Widget _buildMainActionButtons(AsyncValue<List<Word>> wordsAsync) {
    return Column(
      children: [
        // 主按钮：学习新词
        SizedBox(
          width: double.infinity,
          child: _buildGradientButton(
            label: 'Learn',
            icon: Icons.add_rounded,
            gradient: _primaryGradient,
            onTap: () => _showCountPicker(context, ref),
          ),
        ),
        const SizedBox(height: 12),
        // 次按钮：复习
        wordsAsync.when(
          data: (words) => SizedBox(
            width: double.infinity,
            child: _buildOutlineButton(
              label: words.isEmpty ? 'Finished' : 'Review',
              icon: Icons.refresh_rounded,
              enabled: words.isNotEmpty,
              onTap: words.isEmpty
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyScreen(initialWords: words),
                  ),
                );
              },
            ),
          ),
          loading: () => SizedBox(
            width: double.infinity,
            child: _buildOutlineButton(
              label: '加载中...',
              icon: Icons.refresh_rounded,
              enabled: false,
              onTap: null,
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// 渐变主按钮
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 描边次按钮
  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final color = enabled ? _accentColor : _secondaryText;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 6. 快捷功能入口 ==========
  // ========== 6. 快捷功能入口 ==========
  Widget _buildQuickActions() {
    final items = [
      {'icon': Icons.error_rounded, 'label': '错词本', 'color': const Color(0xFFEF4444)},
      {'icon': Icons.menu_book_rounded, 'label': '生词本', 'color': const Color(0xFF0EA5E9)},
      {'icon': Icons.star_rounded, 'label': '收藏本', 'color': const Color(0xFFFFB74D)},
      {'icon': Icons.emoji_events_rounded, 'label': '成就徽章', 'color': _basicColor},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '更多功能',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                switch (item['label'] as String) {
                  case '错词本':
                    setState(() {
                      _selectedIndex = 1;
                    });
                    break;
                  case '生词本':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewWordScreen()),
                    );
                    break;
                  case '收藏本':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoriteWordScreen()),
                    );
                    break;
                  case '成就徽章':
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('成就系统即将上线'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    break;
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: item['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(fontSize: 12, color: _primaryText),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ========== 加载/错误占位卡片 ==========
  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: _secondaryText)),
      ),
    );
  }

  Widget _buildDailySentenceCard() {
    final now = DateTime.now();
    final index = now.day % dailySentencePool.length;
    final sentence = dailySentencePool[index];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _accentColor.withOpacity(0.07),
        border: Border.all(color: _accentColor.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sentence.en,
            style: TextStyle(
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia',
              color: _accentColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sentence.cn,
            style: TextStyle(
              fontSize: 12.5,
              color: _secondaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height:4),
          Text(
            sentence.source,
            style: TextStyle(
              fontSize: 11,
              color: _secondaryText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 词库名称映射 ==========
  String _getCategoryName(String category) {
    switch (category) {
      case 'cet4':
        return '四级词汇';
      case 'cet6':
        return '六级词汇';
      case 'ky':
        return '考研词汇';
      default:
        return '选择词库';
    }
  }

  // ========== 背新词数量选择弹窗 ==========
  void _showCountPicker(BuildContext context, WidgetRef ref) {
    final List<int> presetCounts = [10, 20, 30, 40, 50,60,70,80];
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
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
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
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                              decoration: BoxDecoration(
                                color: isSelected ? _accentColor : _accentBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _primaryText,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  fontSize: 28,
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


// ========== 开始学习新词逻辑 ==========
  void _startLearningNewWords(BuildContext context, WidgetRef ref, int count) async {
    // 显示加载提示
    final snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('加载中...'),
        duration: const Duration(days: 1), // 加载完成前一直显示
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      // 正确写法：通过 .future 获取异步任务，真正等待加载完成
      final words = await ref.refresh(newWordsProvider(count).future);

      // 加载完成，隐藏加载提示
      snackBar.close();

      // 校验页面是否还在
      if (!context.mounted) return;

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

      // 数据就绪后再跳转
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudyScreen(initialWords: words),
        ),
      );
    } catch (e) {
      snackBar.close();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载失败: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildEmptyLibraryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: _secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有导入词库',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '导入对应词库后即可开始背单词',
            style: TextStyle(
              fontSize: 13,
              color: _secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _buildOutlineButton(
              label: '去导入词库',
              icon: Icons.add_rounded,
              enabled: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WordLibraryScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}
