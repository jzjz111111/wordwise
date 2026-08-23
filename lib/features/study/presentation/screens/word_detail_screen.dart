import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/word_detail_provider.dart';
import '../providers/wrong_word_provider.dart';
import '../providers/study_provider.dart';
import '../../domain/entities/study_record.dart';
import '../../domain/entities/word.dart';

class WordDetailScreen extends ConsumerWidget {
  final int wordId;

  const WordDetailScreen({
    super.key,
    required this.wordId,
  });

  // 全局配色 - 与错词本完全统一的INS极简色系
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _warningColor = Color(0xFFFF8A75);
  static const Color _successColor = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(wordDetailProvider(wordId));

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '单词详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, size: 22),
            color: _primaryText,
            onPressed: () {
              detailAsync.whenData((detail) {
                final tts = FlutterTts();
                tts.speak(detail.$1.word);
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: detailAsync.when(
        data: (data) => _buildContent(context, ref, data.$1, data.$2),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _accentColor,
            strokeWidth: 2,
          ),
        ),
        error: (err, stack) => _buildErrorState(context, ref, err),
      ),
    );
  }

  // 核心内容区 - 交错入场动画
  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      Word word,
      StudyRecord? record,
      ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedItem(
            delay: 0,
            child: _buildWordHeader(word),
          ),
          _buildAnimatedItem(
            delay: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('释义'),
                _buildMeaningCard(word.meaning),
              ],
            ),
          ),
          if (word.example != null && word.example!.isNotEmpty)
            _buildAnimatedItem(
              delay: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('例句'),
                  _buildExampleCard(word.example!),
                ],
              ),
            ),
          if (record != null)
            _buildAnimatedItem(
              delay: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('学习状态'),
                  _buildStatusCard(record),
                ],
              ),
            ),
          _buildAnimatedItem(
            delay: 400,
            child: _buildActionButton(context, ref, word),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 交错入场动画封装
  Widget _buildAnimatedItem({required int delay, required Widget child}) {
    const totalDuration = 500;
    final startPoint = delay / totalDuration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: totalDuration),
      curve: Interval(
        startPoint.clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // 单词头部卡片
  Widget _buildWordHeader(Word word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (word.phoneticUk != null || word.phoneticUs != null) ...[
                  if (word.phoneticUk != null)
                    Text(
                      '英  ${word.phoneticUk}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondaryText,
                        height: 1.5,
                      ),
                    ),
                  if (word.phoneticUs != null)
                    Text(
                      '美  ${word.phoneticUs}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondaryText,
                        height: 1.5,
                      ),
                    ),
                ],
              ],
            ),
          ),
          _buildSoundButton(word.word),
        ],
      ),
    );
  }

  // 发音按钮 - 带按压缩放动效
  Widget _buildSoundButton(String wordText) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.92),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () {
            final tts = FlutterTts();
            tts.speak(wordText);
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _accentBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.volume_up_outlined,
                color: _accentColor,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  // 模块标题 - 极简竖线装饰
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // 释义卡片
  Widget _buildMeaningCard(String meaning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        meaning,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: _primaryText,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // 例句卡片 - 淡色背景区分层级
  Widget _buildExampleCard(String example) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accentBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        example,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: _primaryText.withOpacity(0.85),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // 学习状态卡片 - 带进度条动效
  Widget _buildStatusCard(StudyRecord record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              icon: Icons.refresh_outlined,
              value: '${record.reviewCount}',
              label: '复习次数',
              unit: '次',
            ),
          ),
          Container(width: 1, height: 40, color: _bgColor),
          Expanded(
            child: _buildStatusItem(
              icon: Icons.bar_chart_outlined,
              value: '${record.masteryLevel}',
              label: '掌握程度',
              unit: '/5',
              progress: record.masteryLevel / 5,
            ),
          ),
          Container(width: 1, height: 40, color: _bgColor),
          Expanded(
            child: _buildStatusItem(
              icon: Icons.event_available_outlined,
              value: _formatDate(record.nextReviewDate),
              label: '下次复习',
            ),
          ),
        ],
      ),
    );
  }

  // 状态项组件
  Widget _buildStatusItem({
    required IconData icon,
    required String value,
    required String label,
    String? unit,
    double? progress,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _accentBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accentColor, size: 18),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            if (unit != null)
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: _secondaryText),
              ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _bgColor,
              valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
              minHeight: 3,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _secondaryText),
        ),
      ],
    );
  }

  // 主操作按钮 - 悬浮发光+按压缩放
  Widget _buildActionButton(BuildContext context, WidgetRef ref, Word word) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.97),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () async {
            try {
              final repository = ref.read(wordRepositoryProvider);
              await repository.studyWord(wordId: word.id!, quality: 5);

              final wrongRepo = ref.read(wrongWordRepositoryProvider);
              await wrongRepo.removeWrongWord(word.id!);

              ref.invalidate(wrongWordsProvider);
              ref.invalidate(wordDetailProvider(wordId));

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar('已复习并移除错词', isSuccess: true),
              );
              Navigator.pop(context);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar('操作失败: $e'),
              );
            }
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.only(top: 32),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '复习这个词',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
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

  // 错误状态页
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.error_outline, size: 32, color: _warningColor),
          ),
          const SizedBox(height: 20),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            err.toString(),
            style: const TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.invalidate(wordDetailProvider(wordId)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 极简悬浮 SnackBar
  SnackBar _buildSnackBar(String text, {bool isSuccess = false}) {
    return SnackBar(
      content: Text(
        text,
        style: TextStyle(
          color: isSuccess ? _successColor : _primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      backgroundColor: _cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
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
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import '../providers/word_detail_provider.dart';
// import '../providers/wrong_word_provider.dart';
// import '../providers/study_provider.dart';
// import '../../domain/entities/study_record.dart';
// import '../../domain/entities/word.dart';
//
// class WordDetailScreen extends ConsumerWidget {
//   final int wordId;
//
//   const WordDetailScreen({
//     super.key,
//     required this.wordId,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final detailAsync = ref.watch(wordDetailProvider(wordId));
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('📖 单词详情'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.volume_up),
//             onPressed: () {
//               detailAsync.whenData((detail) {
//                 final tts = FlutterTts();
//                 tts.speak(detail.$1.word);
//               });
//             },
//           ),
//         ],
//       ),
//       body: detailAsync.when(
//         data: (data) => _buildContent(context, ref, data.$1, data.$2),
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 48, color: Colors.red),
//               const SizedBox(height: 16),
//               Text('加载失败: $err'),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   ref.invalidate(wordDetailProvider(wordId));
//                 },
//                 child: const Text('重试'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContent(
//       BuildContext context,
//       WidgetRef ref,
//       Word word,
//       StudyRecord? record,
//       ) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 单词 + 音标
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       word.word,
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     if (word.phoneticUk != null || word.phoneticUs != null) ...[
//                       if (word.phoneticUk != null)
//                         Text(
//                           '英 ${word.phoneticUk}',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       if (word.phoneticUs != null)
//                         Text(
//                           '美 ${word.phoneticUs}',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                     ],
//                   ],
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   final tts = FlutterTts();
//                   tts.speak(word.word);
//                 },
//                 icon: const Icon(Icons.volume_up, size: 32),
//                 color: Colors.blue,
//               ),
//             ],
//           ),
//
//           const Divider(height: 32),
//
//           // 释义
//           const Text(
//             '📝 释义',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               word.meaning,
//               style: const TextStyle(fontSize: 18),
//             ),
//           ),
//
//           const SizedBox(height: 24),
//
//           // 例句
//           if (word.example != null && word.example!.isNotEmpty) ...[
//             const Text(
//               '💬 例句',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.blue[100]!),
//               ),
//               child: Text(
//                 word.example!,
//                 style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//
//           // 学习状态
//           if (record != null) ...[
//             const Text(
//               '📊 学习状态',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             _buildStatusCard(record),
//             const SizedBox(height: 24),
//           ],
//
//           // 操作按钮
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () async {
//                     try {
//                       // 1. 复习次数 +1（调用 SM-2 算法更新学习记录）
//                       final repository = ref.read(wordRepositoryProvider);
//                       await repository.studyWord(
//                         wordId: word.id!,
//                         quality: 5,
//                       );
//
//                       // 2. 从错词本中删除（本地 + 云端）
//                       final wrongRepo = ref.read(wrongWordRepositoryProvider);
//                       await wrongRepo.removeWrongWord(word.id!);
//
//                       // 3. 刷新页面数据
//                       ref.invalidate(wrongWordsProvider);
//                       ref.invalidate(wordDetailProvider(wordId));
//
//                       // 4. 提示用户并返回
//                       if (!context.mounted) return;
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('✅ 已复习并移除错词'),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                       Navigator.pop(context);
//                     } catch (e) {
//                       if (!context.mounted) return;
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('操作失败: $e')),
//                       );
//                     }
//                   },
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('复习这个词'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusCard(StudyRecord record) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatusItem(
//             '🔄',
//             '${record.reviewCount}次',
//             '复习次数',
//           ),
//           _buildStatusItem(
//             '📊',
//             '${record.masteryLevel}/5',
//             '掌握程度',
//           ),
//           _buildStatusItem(
//             '📅',
//             _formatDate(record.nextReviewDate),
//             '下次复习',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusItem(String icon, String value, String label) {
//     return Column(
//       children: [
//         Text(icon, style: const TextStyle(fontSize: 24)),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//         ),
//       ],
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final target = DateTime(date.year, date.month, date.day);
//
//     if (target == today) return '今天';
//     if (target == today.add(const Duration(days: 1))) return '明天';
//     if (target == today.subtract(const Duration(days: 1))) return '昨天';
//
//     return '${date.month}/${date.day}';
//   }
// }