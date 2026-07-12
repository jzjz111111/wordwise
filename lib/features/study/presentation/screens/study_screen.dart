import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_provider.dart';
import '../../domain/entities/word.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  /// 当前是否显示卡片背面（释义）
  bool _isShowingBack = false;

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyStateProvider);
    final notifier = ref.read(studyStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          studyState.isLoading
              ? '加载中...'
              : studyState.hasMoreWords
              ? '学习 ${studyState.progress}'
              : '🎉 完成！',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildBody(studyState, notifier),
      ),
    );
  }

  Widget _buildBody(
      StudyState state,
      StudyNotifier notifier,
      ) {
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
              onPressed: () => notifier.refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 没有单词（已完成）
    if (!state.hasMoreWords) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 今日所有单词已完成！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共学习了 ${state.words.length} 个单词',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回首页'),
            ),
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
          value: state.currentIndex / state.words.length,
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
                onTap: () => _rateWord(notifier, 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '模糊',
                icon: Icons.help_outline,
                color: Colors.orange,
                quality: 3,
                onTap: () => _rateWord(notifier, 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRatingButton(
                label: '认识',
                icon: Icons.check,
                color: Colors.green,
                quality: 5,
                onTap: () => _rateWord(notifier, 5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 提示翻转
        Text(
          '👆 点击卡片查看释义',
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
          '👆 点击翻转',
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
          '👆 点击返回',
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
  void _rateWord(StudyNotifier notifier, int quality) {
    // 重置卡片翻转状态
    setState(() {
      _isShowingBack = false;
    });
    // 调用评分方法
    notifier.rateWord(quality);
  }
}