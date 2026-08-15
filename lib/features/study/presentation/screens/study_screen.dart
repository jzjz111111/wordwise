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
  /// 当前是否显示卡片背面（释义）
  bool _isShowingBack = false;

  @override
  void initState() {
    super.initState();
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
      debugPrint('❌ StudyScreen 没有收到 initialWords');
      // 如果没有传入单词，加载空列表
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
      appBar: AppBar(
        title: Text(
          studyState.isLoading
              ? '加载中...'
              : studyState.hasMoreWords
              ? '学习 ${studyState.progress}'
              : '完成！',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildBody(studyState),
      ),
    );
  }

  /// 跳转到拼写测试页（统一封装，带生命周期保护）
  void _navigateToSpellTest(List<Word> words) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 先更新通知，再执行跳转
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
      return const Center(child: CircularProgressIndicator());
    }

    // 错误
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('错误: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(studyStateProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 没有单词（已完成）→ 仅显示加载提示，跳转由 ref.listen 统一触发
    if (!state.hasMoreWords) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在进入拼写测试...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 有单词 → 显示卡片
    final word = state.currentWord!;
    return Column(
      children: [
        // 进度指示
        LinearProgressIndicator(
          value: state.words.isNotEmpty ? state.currentIndex / state.words.length : 0,
          backgroundColor: Colors.grey[200],
          color: Colors.blue,
        ),
        const SizedBox(height: 24),

        // 单词卡片
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isShowingBack = !_isShowingBack;
              });
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: _isShowingBack
                      ? _buildCardBack(word)
                      : _buildCardFront(word),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 评分按钮
        Row(
          children: [
            Expanded(
              child: _buildRatingButton(
                label: '忘记',
                icon: Icons.close,
                color: Colors.red,
                quality: 0,
                onTap: () => _rateWord(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '模糊',
                icon: Icons.help_outline,
                color: Colors.orange,
                quality: 3,
                onTap: () => _rateWord(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '认识',
                icon: Icons.check,
                color: Colors.green,
                quality: 5,
                onTap: () => _rateWord(5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 提示翻转
        Text(
          '点击卡片查看释义',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
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
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (word.phoneticUk != null)
          Text(
            '英 ${word.phoneticUk}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        if (word.phoneticUs != null)
          Text(
            '美 ${word.phoneticUs}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          '点击翻转',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 卡片背面（显示释义 + 例句）
  Widget _buildCardBack(Word word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          word.meaning,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (word.example != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${word.example}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '点击返回',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 评分按钮
  Widget _buildRatingButton({
    required String label,
    required IconData icon,
    required Color color,
    required int quality,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
      // 静默失败，不影响用户体验
      debugPrint('更新通知失败: $e');
    }
  }
}