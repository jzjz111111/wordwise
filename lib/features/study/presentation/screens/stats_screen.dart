import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/study_stats_provider.dart';
import '../../domain/entities/study_stats.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final dailyStats = ref.watch(dailyStudyStatsProvider);
    final distribution = ref.watch(masteryDistributionProvider);
    final totalStats = ref.watch(totalStudyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 学习统计'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总统计卡片
            totalStats.when(
              data: (stats) => _buildTotalStatsCard(stats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox(height: 100, child: Center(child: Text('加载失败'))),
            ),
            const SizedBox(height: 24),

            // 近7天趋势图
            const Text(
              '📈 近7天学习趋势',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            dailyStats.when(
              data: (data) => _buildLineChart(data),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox(height: 200, child: Center(child: Text('加载失败'))),
            ),
            const SizedBox(height: 24),

            // 掌握程度分布
            const Text(
              '🎯 掌握程度分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            distribution.when(
              data: (data) => _buildPieChart(data),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox(height: 200, child: Center(child: Text('加载失败'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStatsCard(TotalStudyStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('📚', '${stats.totalWords}', '已学单词'),
            _buildStatItem('📅', '${stats.totalDays}', '学习天数'),
            _buildStatItem('🔥', '${stats.consecutiveDays}', '连续学习'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<DailyStudyStats> data) {
    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('暂无学习数据')),
      );
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
              return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
            },
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
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
              }).toList(),
              isCurved: true,
              barWidth: 3,
              color: Colors.blue,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withAlpha(30),
              ),
              dotData: FlDotData(show: true),
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
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final sections = [
      PieChartSectionData(
        value: data.mastered.toDouble(),
        color: Colors.green,
        title: '${(data.mastered / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: data.learning.toDouble(),
        color: Colors.orange,
        title: '${(data.learning / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: data.notStarted.toDouble(),
        color: Colors.grey,
        title: '${(data.notStarted / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(Colors.green, '已掌握', data.mastered),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.orange, '学习中', data.learning),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.grey, '未学习', data.notStarted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text('$label: $count'),
      ],
    );
  }
}