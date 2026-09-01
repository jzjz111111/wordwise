import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_provider.dart';
import '../../domain/entities/word.dart';
import 'spell_test_screen.dart';
import 'choice_test_screen.dart';
import '../../../../core/services/notification_service.dart';

class StudyScreen extends ConsumerStatefulWidget {
  final List<Word>? initialWords;

  const StudyScreen({super.key, this.initialWords});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  // 全局配色 - 与前两页完全统一
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);

  // 评分按钮配色 - 低饱和莫兰迪色系
  static const Color _forgetColor = Color(0xFFFF8A75);
  static const Color _fuzzyColor = Color(0xFFFFB74D);
  static const Color _knowColor = Color(0xFF81C784);

  /// 当前是否显示卡片背面（释义）
  bool _isShowingBack = false;

  @override
  void initState() {
    super.initState();
    // 帧构建完成后再修改 provider，避开 Riverpod 构建期保护
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadWords();
    });
  }

  void _loadWords() {
    final notifier = ref.read(studyStateProvider.notifier);
    if (widget.initialWords != null && widget.initialWords!.isNotEmpty) {
      debugPrint('✅ StudyScreen 加载 ${widget.initialWords!.length} 个单词');
      notifier.loadWords(widget.initialWords!);
    } else {
      debugPrint('❌ StudyScreen 没有收到 initialWords,加载复习单词');
      notifier.loadWords([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyStateProvider);

    // 统一监听状态变化：仅在「刚学完所有单词」时执行一次跳转（边沿触发）
    ref.listen<StudyState>(studyStateProvider, (previous, current) {
      final justCompleted = !current.hasMoreWords && previous?.hasMoreWords == true;
      if (justCompleted) {
        _navigateToSpellTest(current.words);
      }
    });

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: Text(
          studyState.isLoading
              ? '加载中'
              : studyState.hasMoreWords
              ? studyState.progress
              : '完成',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _buildBody(studyState),
      ),
    );
  }

  /// 跳转到拼写测试页（统一封装，带生命周期保护）
  void _navigateToSpellTest(List<Word> words) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _updateNotification();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SpellTestScreen(words: words),
        ),
      );
    });
  }

  Widget _buildBody(StudyState state) {
    // 加载中
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      );
    }

    // 错误状态
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    // 没有单词（已完成）
    if (!state.hasMoreWords) {
      return _buildCompleteState();
    }

    // 有单词 → 核心学习界面
    final word = state.currentWord!;
    return Column(
      children: [
        // 精致圆角进度条
        _buildProgressBar(state),
        const SizedBox(height: 24),

        // 3D翻转单词卡片
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isShowingBack = !_isShowingBack;
              });
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _isShowingBack ? pi : 0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                // 添加透视效果，增强3D立体感
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value);

                // 翻转超过90°时切换正反面，避免穿帮
                final showBack = value > pi / 2;

                return Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
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
                    child: Center(
                      child: showBack
                      // 背面预先翻转180°，卡片整体转到位后文字刚好正向
                          ? Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _buildCardBack(word),
                      )
                          : _buildCardFront(word),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 评分按钮组
        Row(
          children: [
            Expanded(
              child: _buildRatingButton(
                label: '忘记',
                icon: Icons.close,
                color: _forgetColor,
                onTap: () => _rateWord(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '模糊',
                icon: Icons.help_outline,
                color: _fuzzyColor,
                onTap: () => _rateWord(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '认识',
                icon: Icons.check,
                color: _knowColor,
                onTap: () => _rateWord(5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 翻转提示
        Text(
          '点击卡片翻转查看释义',
          style: const TextStyle(
            fontSize: 13,
            color: _secondaryText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // 圆角进度条
  Widget _buildProgressBar(StudyState state) {
    final progress = state.words.isNotEmpty
        ? state.currentIndex / state.words.length
        : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: _accentBg,
        valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
        minHeight: 4,
      ),
    );
  }

  /// 卡片正面（显示英文）
  Widget _buildCardFront(Word word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _primaryText,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (word.phoneticUk != null)
          Text(
            '英  ${word.phoneticUk}',
            style: const TextStyle(
              fontSize: 15,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
        if (word.phoneticUs != null)
          Text(
            '美  ${word.phoneticUs}',
            style: const TextStyle(
              fontSize: 15,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 32),
        Icon(
          Icons.touch_app_outlined,
          size: 20,
          color: _secondaryText.withOpacity(0.6),
        ),
      ],
    );
  }

  /// 卡片背面（显示释义 + 例句）
  Widget _buildCardBack(Word word) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.meaning,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: _primaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (word.example != null && word.example!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${word.example}"',
                style: TextStyle(
                  fontSize: 15,
                  color: _primaryText.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Icon(
            Icons.flip_outlined,
            size: 20,
            color: _secondaryText.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  /// 评分按钮 - 带按压缩放动效
  Widget _buildRatingButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.93),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 26, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _forgetColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.error_outline, size: 32, color: _forgetColor),
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
            error,
            style: const TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.read(studyStateProvider.notifier).refresh(),
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

  // 完成过渡状态页
  Widget _buildCompleteState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            '正在进入拼写测试...',
            style: TextStyle(color: _secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 评分并处理
  void _rateWord(int quality) {
    setState(() {
      _isShowingBack = false;
    });
    ref.read(studyStateProvider.notifier).rateWord(quality);
  }

  /// 更新每日复习通知内容
  Future<void> _updateNotification() async {
    try {
      final service = NotificationService();
      final stats = await ref.read(todayStatsProvider.future);
      final count = stats['todayReview'] ?? 0;
      await service.scheduleDailyReminder(count);
    } catch (e) {
      debugPrint('更新通知失败: $e');
    }
  }
}

