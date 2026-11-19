import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wrong_word_provider.dart';
import 'word_detail_screen.dart';
import '../../../../core/services/tts_service.dart';

class WrongWordScreen extends ConsumerStatefulWidget {
  const WrongWordScreen({super.key});

  @override
  ConsumerState<WrongWordScreen> createState() => _WrongWordScreenState();
}

class _WrongWordScreenState extends ConsumerState<WrongWordScreen> {
  // 配色系统 - INS 低饱和极简风
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _warningColor = Color(0xFFFF8A75);
  static const Color _warningBg = Color(0xFFFFF0ED);
  static const Color _btnBg = Color(0xFFF1F2F6);

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wrongWordsProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '错词本',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 22),
            color: _primaryText,
            onPressed: () => ref.invalidate(wrongWordsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 22),
            color: _primaryText,
            onPressed: () => _showClearDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: _accentColor,
        backgroundColor: _cardColor,
        strokeWidth: 2,
        onRefresh: () async {
          ref.invalidate(wrongWordsProvider);
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: wordsAsync.when(
          data: (words) {
            if (words.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                // 逐行入场动画：渐显 + 上滑
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + index * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildWordCard(word, context),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 2,
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              '加载失败',
              style: TextStyle(color: _secondaryText, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  // 单词卡片 - 极简圆角卡片 + 点击缩放反馈
  Widget _buildWordCard(dynamic word, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordDetailScreen(wordId: word.id!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧图标容器
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _warningBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                color: _warningColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // 单词文本
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // 🔊 发音按钮
            GestureDetector(
              onTap: () => TtsService.instance.speak(word.word),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volume_up_outlined,
                  color: _accentColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 删除按钮
            GestureDetector(
              onTap: () {
                final repo = ref.read(wrongWordRepositoryProvider);
                repo.removeWrongWord(word.id!);
                ref.invalidate(wrongWordsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar('已移除: ${word.word}'),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _btnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: _secondaryText,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 空状态 - 极简排版
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 36,
              color: Color(0xFF66BB6A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '暂无错词',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '继续保持哦',
            style: TextStyle(
              fontSize: 13,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // 极简悬浮 SnackBar
  SnackBar _buildSnackBar(String text) {
    return SnackBar(
      content: Text(
        text,
        style: const TextStyle(color: _primaryText, fontSize: 14),
      ),
      backgroundColor: _cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  // 确认弹窗 - 极简圆角风格
  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _cardColor,
        title: const Text(
          '清空错词本',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _primaryText,
          ),
        ),
        content: const Text(
          '确定要清空所有错词吗？此操作不可撤销。',
          style: TextStyle(
            fontSize: 14,
            color: _secondaryText,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _secondaryText,
              textStyle: const TextStyle(fontWeight: FontWeight.w400),
            ),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final repo = ref.read(wrongWordRepositoryProvider);
              repo.clearWrongWords();
              ref.invalidate(wrongWordsProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar('已清空错词本'),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: _warningColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
