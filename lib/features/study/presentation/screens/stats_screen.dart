import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/study_stats_provider.dart';
import '../../domain/entities/study_stats.dart';
import '../widgets/streak_calendar.dart';


class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with WidgetsBindingObserver {
  // 全局配色 - 与学习页完全统一
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);

  // 掌握程度配色 - 与学习页评分色系呼应
  static const Color _basicColor = Color(0xFFFFB74D);
  static const Color _intermediateColor = Color(0xFF8A9EDB);
  static const Color _advancedColor = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App从后台切回前台，强制刷新页面，Riverpod provider会自动重新拉取数据
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dailyStudyStatsProvider);
      ref.invalidate(masteryDistributionProvider);
      ref.invalidate(totalStudyStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyStats = ref.watch(dailyStudyStatsProvider);
    final distribution = ref.watch(masteryDistributionProvider);
    final totalStats = ref.watch(totalStudyStatsProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '学习统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            totalStats.when(
              data: (stats) => _buildTotalStatsCard(stats),
              loading: () => const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
                ),
              ),
              error: (err, stack) => SizedBox(
                height: 120,
                child: Center(
                  child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildStreakCalendarSection(totalStats),
            const SizedBox(height: 28),

            const Text(
              '近7天学习趋势',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 12),
            dailyStats.when(
              data: (data) => _buildLineChart(data),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
                ),
              ),
              error: (err, stack) => SizedBox(
                height: 200,
                child: Center(
                  child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              '掌握程度分布',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 12),
            distribution.when(
              data: (data) => _buildPieChart(data),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
                ),
              ),
              error: (err, stack) => SizedBox(
                height: 200,
                child: Center(
                  child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCalendarSection(AsyncValue<TotalStudyStats> totalAsync) {
    return totalAsync.when(
      data: (totalData) {
        // TODO：当前模拟模式，仅UI体验，无真实打卡业务
        // 后续接入真实打卡：把mockCheckedDates替换为数据库读取的真实日期列表
        final mockCheckedDates = <DateTime>[];
        final int streak = totalData.consecutiveDays;
        final DateTime today = DateTime.now();
        final DateTime cleanToday = DateTime(today.year, today.month, today.day);

        for (int i = 0; i < streak; i++) {
          mockCheckedDates.add(cleanToday.subtract(Duration(days: i)));
        }

        return StreakCalendar(
          checkedDates: mockCheckedDates,
          streakDays: totalData.consecutiveDays,
          accentColor: _accentColor,
          cardBgColor: _cardColor,
          streakBadgeColor: _basicColor,
        );
      },
      loading: () => Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTotalStatsCard(TotalStudyStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.menu_book_rounded, '${stats.totalWords}', '已学单词'),
          _buildStatItem(Icons.calendar_today_rounded, '${stats.totalDays}', '学习天数'),
          _buildStatItem(Icons.local_fire_department_rounded, '${stats.consecutiveDays}', '连续学习'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 26, color: _accentColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _primaryText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _secondaryText),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<DailyStudyStats> data) {
    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return _buildEmptyState('暂无学习数据');
    }

    final maxCount = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxCount > 5 ? maxCount / 5 : 1,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: _accentBg, strokeWidth: 1);
            },
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const Text('');
                  final date = data[index].date;
                  return Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 11, color: _secondaryText),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11, color: _secondaryText),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
              }).toList(),
              isCurved: true,
              barWidth: 3,
              color: _accentColor,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _accentColor.withOpacity(0.25),
                    _accentColor.withOpacity(0.05),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: _accentColor,
                  strokeWidth: 2,
                  strokeColor: _cardColor,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxCount > 0 ? maxCount * 1.2 : 5,
        ),
      ),
    );
  }

  Widget _buildPieChart(MasteryDistribution data) {
    final total = data.total;
    if (total == 0) {
      return _buildEmptyState('暂无已学单词');
    }

    final sections = [
      PieChartSectionData(
        value: data.basic.toDouble(),
        color: _basicColor,
        title: '${(data.basic / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: data.intermediate.toDouble(),
        color: _intermediateColor,
        title: '${(data.intermediate / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: data.advanced.toDouble(),
        color: _advancedColor,
        title: '${(data.advanced / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(_basicColor, '初级掌握', data.basic, total),
              const SizedBox(height: 10),
              _buildLegendItem(_intermediateColor, '中级掌握', data.intermediate, total),
              const SizedBox(height: 10),
              _buildLegendItem(_advancedColor, '高级掌握', data.advanced, total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _primaryText),
        ),
        const SizedBox(width: 4),
        Text(
          '$count · $percentage%',
          style: const TextStyle(fontSize: 12, color: _secondaryText),
        ),
      ],
    );
  }

  /// 统一空状态样式
  Widget _buildEmptyState(String text) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _accentBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: _secondaryText),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../providers/study_stats_provider.dart';
// import '../../domain/entities/study_stats.dart';
//
// class StatsScreen extends ConsumerStatefulWidget {
//   const StatsScreen({super.key});
//
//   @override
//   ConsumerState<StatsScreen> createState() => _StatsScreenState();
// }
//
// class _StatsScreenState extends ConsumerState<StatsScreen> {
//   // 全局配色 - 与学习页完全统一
//   static const Color _bgColor = Color(0xFFF7F8FA);
//   static const Color _cardColor = Colors.white;
//   static const Color _primaryText = Color(0xFF2D3142);
//   static const Color _secondaryText = Color(0xFF9AA0B4);
//   static const Color _accentColor = Color(0xFF8A9EDB);
//   static const Color _accentBg = Color(0xFFF0F3FC);
//
//   // 掌握程度配色 - 与学习页评分色系呼应
//   static const Color _basicColor = Color(0xFFFFB74D);
//   static const Color _intermediateColor = Color(0xFF8A9EDB);
//   static const Color _advancedColor = Color(0xFF81C784);
//
//   @override
//   Widget build(BuildContext context) {
//     final dailyStats = ref.watch(dailyStudyStatsProvider);
//     final distribution = ref.watch(masteryDistributionProvider);
//     final totalStats = ref.watch(totalStudyStatsProvider);
//
//     return Scaffold(
//       backgroundColor: _bgColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: _primaryText),
//         title: const Text(
//           '学习统计',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//             color: _primaryText,
//             letterSpacing: 1.2,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             totalStats.when(
//               data: (stats) => _buildTotalStatsCard(stats),
//               loading: () => const SizedBox(
//                 height: 120,
//                 child: Center(
//                   child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
//                 ),
//               ),
//               error: (err, stack) => SizedBox(
//                 height: 120,
//                 child: Center(
//                   child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 28),
//
//             const Text(
//               '近7天学习趋势',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: _primaryText,
//               ),
//             ),
//             const SizedBox(height: 12),
//             dailyStats.when(
//               data: (data) => _buildLineChart(data),
//               loading: () => const SizedBox(
//                 height: 200,
//                 child: Center(
//                   child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
//                 ),
//               ),
//               error: (err, stack) => SizedBox(
//                 height: 200,
//                 child: Center(
//                   child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 28),
//
//             const Text(
//               '掌握程度分布',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: _primaryText,
//               ),
//             ),
//             const SizedBox(height: 12),
//             distribution.when(
//               data: (data) => _buildPieChart(data),
//               loading: () => const SizedBox(
//                 height: 200,
//                 child: Center(
//                   child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
//                 ),
//               ),
//               error: (err, stack) => SizedBox(
//                 height: 200,
//                 child: Center(
//                   child: Text('加载失败', style: TextStyle(color: _secondaryText, fontSize: 14)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTotalStatsCard(TotalStudyStats stats) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
//       decoration: BoxDecoration(
//         color: _cardColor,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem(Icons.menu_book_rounded, '${stats.totalWords}', '已学单词'),
//           _buildStatItem(Icons.calendar_today_rounded, '${stats.totalDays}', '学习天数'),
//           _buildStatItem(Icons.local_fire_department_rounded, '${stats.consecutiveDays}', '连续学习'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem(IconData icon, String value, String label) {
//     return Column(
//       children: [
//         Icon(icon, size: 26, color: _accentColor),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.w600,
//             color: _primaryText,
//             letterSpacing: 0.5,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: _secondaryText),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLineChart(List<DailyStudyStats> data) {
//     if (data.isEmpty || data.every((d) => d.count == 0)) {
//       return _buildEmptyState('暂无学习数据');
//     }
//
//     final maxCount = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);
//
//     return SizedBox(
//       height: 200,
//       child: LineChart(
//         LineChartData(
//           gridData: FlGridData(
//             show: true,
//             horizontalInterval: maxCount > 5 ? maxCount / 5 : 1,
//             getDrawingHorizontalLine: (value) {
//               return const FlLine(color: _accentBg, strokeWidth: 1);
//             },
//             drawVerticalLine: false,
//           ),
//           titlesData: FlTitlesData(
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   final index = value.toInt();
//                   if (index < 0 || index >= data.length) return const Text('');
//                   final date = data[index].date;
//                   return Text(
//                     '${date.month}/${date.day}',
//                     style: const TextStyle(fontSize: 11, color: _secondaryText),
//                   );
//                 },
//               ),
//             ),
//             leftTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 32,
//                 getTitlesWidget: (value, meta) {
//                   return Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(fontSize: 11, color: _secondaryText),
//                   );
//                 },
//               ),
//             ),
//             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           ),
//           borderData: FlBorderData(show: false),
//           lineBarsData: [
//             LineChartBarData(
//               spots: data.asMap().entries.map((entry) {
//                 return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
//               }).toList(),
//               isCurved: true,
//               barWidth: 3,
//               color: _accentColor,
//               belowBarData: BarAreaData(
//                 show: true,
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     _accentColor.withOpacity(0.25),
//                     _accentColor.withOpacity(0.05),
//                   ],
//                 ),
//               ),
//               dotData: FlDotData(
//                 show: true,
//                 getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
//                   radius: 3.5,
//                   color: _accentColor,
//                   strokeWidth: 2,
//                   strokeColor: _cardColor,
//                 ),
//               ),
//             ),
//           ],
//           minX: 0,
//           maxX: (data.length - 1).toDouble(),
//           minY: 0,
//           maxY: maxCount > 0 ? maxCount * 1.2 : 5,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPieChart(MasteryDistribution data) {
//     final total = data.total;
//     if (total == 0) {
//       return _buildEmptyState('暂无已学单词');
//     }
//
//     final sections = [
//       PieChartSectionData(
//         value: data.basic.toDouble(),
//         color: _basicColor,
//         title: '${(data.basic / total * 100).toInt()}%',
//         radius: 50,
//         titleStyle: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w500,
//           color: Colors.white,
//         ),
//       ),
//       PieChartSectionData(
//         value: data.intermediate.toDouble(),
//         color: _intermediateColor,
//         title: '${(data.intermediate / total * 100).toInt()}%',
//         radius: 50,
//         titleStyle: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w500,
//           color: Colors.white,
//         ),
//       ),
//       PieChartSectionData(
//         value: data.advanced.toDouble(),
//         color: _advancedColor,
//         title: '${(data.advanced / total * 100).toInt()}%',
//         radius: 50,
//         titleStyle: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w500,
//           color: Colors.white,
//         ),
//       ),
//     ];
//
//     return SizedBox(
//       height: 200,
//       child: Row(
//         children: [
//           Expanded(
//             child: PieChart(
//               PieChartData(
//                 sections: sections,
//                 centerSpaceRadius: 36,
//                 sectionsSpace: 1.5,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildLegendItem(_basicColor, '初级掌握', data.basic, total),
//               const SizedBox(height: 10),
//               _buildLegendItem(_intermediateColor, '中级掌握', data.intermediate, total),
//               const SizedBox(height: 10),
//               _buildLegendItem(_advancedColor, '高级掌握', data.advanced, total),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLegendItem(Color color, String label, int count, int total) {
//     final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(3),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 13, color: _primaryText),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           '$count · $percentage%',
//           style: const TextStyle(fontSize: 12, color: _secondaryText),
//         ),
//       ],
//     );
//   }
//
//   /// 统一空状态样式
//   Widget _buildEmptyState(String text) {
//     return Container(
//       height: 200,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: _accentBg,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 14, color: _secondaryText),
//         ),
//       ),
//     );
//   }
// }
