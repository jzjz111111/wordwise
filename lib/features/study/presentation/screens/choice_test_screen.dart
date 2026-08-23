import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/services/ai_service.dart';
import '../providers/choice_test_provider.dart';
import '../../domain/entities/word.dart';
import 'package:flutter/services.dart';

class ChoiceTestScreen extends ConsumerStatefulWidget {
  final List<Word> words;
  const ChoiceTestScreen({super.key, required this.words});

  @override
  ConsumerState<ChoiceTestScreen> createState() => _ChoiceTestScreenState();
}

class _ChoiceTestScreenState extends ConsumerState<ChoiceTestScreen> {
  final FlutterTts _tts = FlutterTts();

  // ====================== 全局配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _correctColor = Color(0xFF81C784);
  static const Color _wrongColor = Color(0xFFFF8A75);

  @override
  void initState() {
    super.initState();
    _initTtsConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(choiceTestProvider.notifier).loadWords(widget.words);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTtsConfig() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _handleCompleted(List<Word> wrongWords) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wrongWords.isNotEmpty) {
        ref.read(choiceTestProvider.notifier).loadWords(wrongWords);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(choiceTestProvider);

    ref.listen<ChoiceTestState>(choiceTestProvider, (previous, current) {
      if (current.isCompleted && previous?.isCompleted != true) {
        _handleCompleted(current.wrongWords);
      }
    });

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '选择测试',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: state.isCompleted
              ? _buildCompletionView(state)
              : _buildTestView(state),
        ),
      ),
    );
  }

  // ==================== 答题主视图 ====================
  Widget _buildTestView(ChoiceTestState state) {
    if (state.words.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      );
    }

    final word = state.currentWord;
    if (word == null) {
      return const Center(child: Text('加载单词失败', style: TextStyle(color: _secondaryText)));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(state),
          const SizedBox(height: 32),

          _buildWordCard(word),
          const SizedBox(height: 28),

          ...List.generate(4, (index) => _buildOptionButton(index, state)),
          const SizedBox(height: 16),

          if (state.showResult) _buildResultArea(state, word),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(ChoiceTestState state) {
    final progress = state.totalCount > 0
        ? (state.currentIndex + 1) / state.totalCount
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '第 ${state.currentIndex + 1} 题',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            Text(
              '${state.currentIndex + 1} / ${state.totalCount}',
              style: const TextStyle(
                fontSize: 14,
                color: _secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _accentBg,
            valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // 单词释义卡片
  Widget _buildWordCard(Word word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
        children: [
          Text(
            word.meaning,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: _primaryText,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (word.phoneticUk != null)
            Text(
              '英  ${word.phoneticUk}',
              style: const TextStyle(fontSize: 14, color: _secondaryText),
            ),
          if (word.phoneticUs != null)
            Text(
              '美  ${word.phoneticUs}',
              style: const TextStyle(fontSize: 14, color: _secondaryText),
            ),
          const SizedBox(height: 24),
          _buildTtsButton(word),
        ],
      ),
    );
  }

  Widget _buildTtsButton(Word word) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.93),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () async {
            await _tts.stop();
            await _tts.speak(word.word);
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _accentBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                size: 28,
                color: _accentColor,
              ),
            ),
          ),
        );
      },
    );
  }

  // 单个选项按钮
  Widget _buildOptionButton(int index, ChoiceTestState state) {
    final isSelected = state.selectedIndex == index;
    final isCorrectOption = state.showResult && index == state.correctIndex;
    final isWrongOption = state.showResult && isSelected && !isCorrectOption;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!state.showResult) {
      bgColor = isSelected ? _accentBg : _cardColor;
      borderColor = isSelected ? _accentColor : Colors.transparent;
      textColor = _primaryText;
    } else if (isCorrectOption) {
      bgColor = _correctColor.withOpacity(0.1);
      borderColor = _correctColor;
      textColor = _correctColor;
    } else if (isWrongOption) {
      bgColor = _wrongColor.withOpacity(0.1);
      borderColor = _wrongColor;
      textColor = _wrongColor;
    } else {
      bgColor = _cardColor;
      borderColor = Colors.transparent;
      textColor = _secondaryText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          double scale = 1.0;
          return GestureDetector(
            onTapDown: (_) {
              if (!state.showResult) setBtnState(() => scale = 0.97);
            },
            onTapUp: (_) => setBtnState(() => scale = 1.0),
            onTapCancel: () => setBtnState(() => scale = 1.0),
            onTap: state.showResult
                ? null
                : () => ref.read(choiceTestProvider.notifier).selectAnswer(index),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                key: ValueKey('${state.currentWord?.word}_$index'),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  state.options[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 结果提示 + 下一题按钮
  Widget _buildResultArea(ChoiceTestState state, Word word) {
    final isLast = state.currentIndex + 1 >= state.totalCount;

    return AnimatedOpacity(
      opacity: state.showResult ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: state.isCorrect
                  ? _correctColor.withOpacity(0.08)
                  : _wrongColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.isCorrect
                    ? _correctColor.withOpacity(0.3)
                    : _wrongColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: state.isCorrect ? _correctColor : _wrongColor,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.isCorrect
                        ? '回答正确'
                        : '正确答案：${word.word}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: state.isCorrect ? _correctColor : _wrongColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setBtnState) {
              double scale = 1.0;
              return GestureDetector(
                onTapDown: (_) => setBtnState(() => scale = 0.96),
                onTapUp: (_) => setBtnState(() => scale = 1.0),
                onTapCancel: () => setBtnState(() => scale = 1.0),
                onTap: () => ref.read(choiceTestProvider.notifier).nextWord(),
                child: AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isLast ? '查看结果' : '下一题',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== 完成页视图 ====================
  Widget _buildCompletionView(ChoiceTestState state) {
    if (state.wrongWords.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
            SizedBox(height: 16),
            Text('正在进入错词重测...', style: TextStyle(color: _secondaryText, fontSize: 14)),
          ],
        ),
      );
    }

    final correctCount = state.totalCount - state.wrongWords.length;
    final learnedWords = state.words.map((w) => w.word).toList();

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _correctColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 40,
                color: _correctColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '全部完成！',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '正确: $correctCount / ${state.totalCount}',
              style: const TextStyle(fontSize: 15, color: _secondaryText),
            ),
            const SizedBox(height: 32),

            // AI 生成段子按钮
            _buildPrimaryButton(
              icon: Icons.auto_awesome_rounded,
              label: 'AI 生成段子',
              onTap: () => _showAIStory(context, learnedWords),
            ),
            const SizedBox(height: 12),

            // 返回首页按钮
            _buildOutlineButton(
              label: '返回首页',
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

  Widget _buildOutlineButton({
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor, width: 1.5),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== AI 功能 ====================
  void _showAIStory(BuildContext context, List<String> words) {
    const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请配置 DEEPSEEK_API_KEY 环境变量'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final aiService = AIService(apiKey: apiKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AIStoryDialog(
        aiService: aiService,
        words: words,
      ),
    );
  }
}

class _AIStoryDialog extends StatefulWidget {
  final AIService aiService;
  final List<String> words;

  const _AIStoryDialog({
    required this.aiService,
    required this.words,
  });

  @override
  State<_AIStoryDialog> createState() => _AIStoryDialogState();
}

class _AIStoryDialogState extends State<_AIStoryDialog> {
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _cardColor = Colors.white;

  String _story = '';
  bool _isGenerating = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateStory();
  }

  Future<void> _generateStory() async {
    try {
      await for (final token in widget.aiService.generateStory(widget.words)) {
        if (mounted) {
          setState(() {
            _story += token;
          });
        }
      }
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isGenerating = false;
          _story = '生成失败，请重试: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: _accentColor, size: 22),
          const SizedBox(width: 8),
          const Text(
            'AI 段子',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.words.map((w) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.withOpacity(0.1), thickness: 0.5),
              const SizedBox(height: 16),
              if (_isGenerating) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '正在创作段子...',
                      style: TextStyle(color: _secondaryText, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(
                _story,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_hasError)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: _secondaryText)),
          ),
        if (!_isGenerating && !_hasError) ...[
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _story));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('已复制到剪贴板'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: _accentColor),
            label: const Text('复制', style: TextStyle(color: _accentColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的', style: TextStyle(color: _accentColor)),
          ),
        ],
        if (_isGenerating && !_hasError)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _secondaryText)),
          ),
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import '../../../../core/services/ai_service.dart';
// import '../providers/choice_test_provider.dart';
// import '../../domain/entities/word.dart';
// import 'package:flutter/services.dart';
//
//
//
// class ChoiceTestScreen extends ConsumerStatefulWidget {
//   final List<Word> words;
//   const ChoiceTestScreen({super.key, required this.words});
//
//   @override
//   ConsumerState<ChoiceTestScreen> createState() => _ChoiceTestScreenState();
// }
//
// class _ChoiceTestScreenState extends ConsumerState<ChoiceTestScreen> {
//   final FlutterTts _tts = FlutterTts();
//
//   @override
//   void initState() {
//     super.initState();
//     _initTtsConfig();
//     // ✅ 延迟到第一帧构建完成后再加载，彻底避开构建期修改状态的问题
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       ref.read(choiceTestProvider.notifier).loadWords(widget.words);
//     });
//   }
//
//   @override
//   void dispose() {
//     _tts.stop();
//     super.dispose();
//   }
//
//   /// TTS 基础配置，保证发音语言、语速符合预期
//   Future<void> _initTtsConfig() async {
//     await _tts.setLanguage('en-US');
//     await _tts.setSpeechRate(0.5);
//     await _tts.setVolume(1.0);
//     await _tts.setPitch(1.0);
//   }
//
//   /// 答题完成回调：错词自动重测
//   void _handleCompleted(List<Word> wrongWords) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       if (wrongWords.isNotEmpty) {
//         ref.read(choiceTestProvider.notifier).loadWords(wrongWords);
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(choiceTestProvider);
//
//     // 监听完成状态，触发错词重测
//     ref.listen<ChoiceTestState>(choiceTestProvider, (previous, current) {
//       if (current.isCompleted && previous?.isCompleted != true) {
//         _handleCompleted(current.wrongWords);
//       }
//     });
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('选择题测试'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: state.isCompleted
//             ? _buildCompletionView(state)
//             : _buildTestView(state),
//       ),
//     );
//   }
//
//   // ==================== 答题主视图 ====================
//   Widget _buildTestView(ChoiceTestState state) {
//     if (state.words.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     final word = state.currentWord;
//     if (word == null) {
//       return const Center(child: Text('加载单词失败'));
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // 进度区域
//           Text('${state.currentIndex + 1} / ${state.totalCount}'),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: state.totalCount > 0
//                 ? (state.currentIndex + 1) / state.totalCount
//                 : 0,
//             backgroundColor: Colors.grey[200],
//             color: Colors.blue,
//           ),
//           const SizedBox(height: 40),
//
//           // 单词释义卡片
//           _buildWordCard(word),
//           const SizedBox(height: 32),
//
//           // 选项列表
//           ...List.generate(4, (index) => _buildOptionButton(index, state)),
//           const SizedBox(height: 16),
//
//           // 答题结果反馈 + 下一题按钮
//           if (state.showResult) _buildResultArea(state, word),
//         ],
//       ),
//     );
//   }
//
//   // 单词释义卡片
//   Widget _buildWordCard(Word word) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         children: [
//           Text(
//             word.meaning,
//             style: const TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (word.phoneticUk != null) Text('英 ${word.phoneticUk}'),
//           const SizedBox(height: 12),
//           IconButton(
//             // 播放前先停止，避免快速点击导致语音叠加
//             onPressed: () async {
//               await _tts.stop();
//               await _tts.speak(word.word);
//             },
//             icon: const Icon(Icons.volume_up, size: 36),
//             color: Colors.blue,
//           ),
//           const Text(
//             '点击听发音',
//             style: TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 单个选项按钮
//   Widget _buildOptionButton(int index, ChoiceTestState state) {
//     final isSelected = state.selectedIndex == index;
//     final isCorrectOption = state.showResult && index == state.correctIndex;
//     final isWrongOption = state.showResult && isSelected && !isCorrectOption;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: state.showResult
//               ? null
//               : () => ref.read(choiceTestProvider.notifier).selectAnswer(index),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             backgroundColor: _getButtonBgColor(
//               isSelected: isSelected,
//               isCorrect: isCorrectOption,
//               isWrong: isWrongOption,
//               showResult: state.showResult,
//             ),
//             foregroundColor: state.showResult ? Colors.white : Colors.black,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//               side: BorderSide(
//                 color: _getButtonBorderColor(
//                   isCorrect: isCorrectOption,
//                   isWrong: isWrongOption,
//                   showResult: state.showResult,
//                 ),
//                 width: 2,
//               ),
//             ),
//           ),
//           child: Text(
//             state.options[index],
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // 结果提示 + 下一题按钮
//   Widget _buildResultArea(ChoiceTestState state, Word word) {
//     final isLast = state.currentIndex + 1 >= state.totalCount;
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: state.isCorrect ? Colors.green[50] : Colors.red[50],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 state.isCorrect ? Icons.check_circle : Icons.error,
//                 color: state.isCorrect ? Colors.green : Colors.red,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   state.isCorrect ? '正确！' : '错误，正确答案是 ${word.word}',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: state.isCorrect ? Colors.green : Colors.red,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: () => ref.read(choiceTestProvider.notifier).nextWord(),
//             child: Text(isLast ? '查看结果' : '下一题'),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ==================== 完成页视图 ====================
//   Widget _buildCompletionView(ChoiceTestState state) {
//     // 有错词：正在加载错词重测
//     if (state.wrongWords.isNotEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('正在进入错词重测...', style: TextStyle(color: Colors.grey)),
//           ],
//         ),
//       );
//     }
//
//     final correctCount = state.totalCount - state.wrongWords.length;
//     final learnedWords = state.words.map((w) => w.word).toList();
//
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.celebration, size: 72, color: Colors.green),
//           const SizedBox(height: 16),
//           const Text(
//             '全部完成！',
//             style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '正确: $correctCount / ${state.totalCount}',
//             style: const TextStyle(fontSize: 18, color: Colors.grey),
//           ),
//           const SizedBox(height: 24),
//
//           // ✅ AI 生成段子按钮
//           ElevatedButton.icon(
//             onPressed: () => _showAIStory(context, learnedWords),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             icon: const Icon(Icons.auto_awesome),
//             label: const Text('AI 生成段子'),
//           ),
//           const SizedBox(height: 12),
//
//           // 返回首页按钮
//           OutlinedButton(
//             onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('返回首页'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== AI 功能 ====================
//
//   void _showAIStory(BuildContext context, List<String> words) {
//     const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
//     if (apiKey.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('请配置 DEEPSEEK_API_KEY 环境变量')),
//       );
//       return;
//     }
//
//     final aiService = AIService(apiKey: apiKey);
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => _AIStoryDialog(
//         aiService: aiService,
//         words: words,
//       ),
//     );
//   }
//   // ==================== 样式工具方法 ====================
//   Color _getButtonBgColor({
//     required bool isSelected,
//     required bool isCorrect,
//     required bool isWrong,
//     required bool showResult,
//   }) {
//     if (!showResult) return Colors.grey[100]!;
//     if (isCorrect) return Colors.green;
//     if (isWrong) return Colors.red;
//     return Colors.grey[300]!;
//   }
//
//   Color _getButtonBorderColor({
//     required bool isCorrect,
//     required bool isWrong,
//     required bool showResult,
//   }) {
//     if (!showResult) return Colors.transparent;
//     if (isCorrect) return Colors.green;
//     if (isWrong) return Colors.red;
//     return Colors.transparent;
//   }
// }
//
// class _AIStoryDialog extends StatefulWidget {
//   final AIService aiService;
//   final List<String> words;
//
//   const _AIStoryDialog({
//     required this.aiService,
//     required this.words,
//   });
//
//   @override
//   State<_AIStoryDialog> createState() => _AIStoryDialogState();
// }
//
// class _AIStoryDialogState extends State<_AIStoryDialog> {
//   String _story = '';
//   bool _isGenerating = true;
//   bool _hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _generateStory();
//   }
//
//   Future<void> _generateStory() async {
//     try {
//       await for (final token in widget.aiService.generateStory(widget.words)) {
//         if (mounted) {
//           setState(() {
//             _story += token;
//           });
//         }
//       }
//       if (mounted) {
//         setState(() {
//           _isGenerating = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _isGenerating = false;
//           _story = '生成失败，请重试: $e';
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Row(
//         children: [
//           Icon(Icons.auto_awesome, color: Colors.purple),
//           SizedBox(width: 8),
//           Text('AI 段子'),
//         ],
//       ),
//       content: Container(
//         constraints: const BoxConstraints(maxWidth: 400, minHeight: 100),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Wrap(
//               spacing: 8,
//               runSpacing: 4,
//               children: widget.words.map((w) {
//                 return Chip(
//                   label: Text(w),
//                   backgroundColor: Colors.purple[50],
//                   labelStyle: const TextStyle(fontWeight: FontWeight.w500),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 16),
//             const Divider(),
//             const SizedBox(height: 16),
//             if (_isGenerating) ...[
//               const Row(
//                 children: [
//                   SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   SizedBox(width: 12),
//                   Text('正在创作段子...', style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//               const SizedBox(height: 12),
//             ],
//             Text(
//               _story,
//               style: const TextStyle(fontSize: 16, height: 1.6),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         if (_hasError)
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('关闭'),
//           ),
//         if (!_isGenerating && !_hasError) ...[
//           TextButton.icon(
//             onPressed: () {
//               Clipboard.setData(ClipboardData(text: _story));
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('已复制到剪贴板')),
//               );
//             },
//             icon: const Icon(Icons.copy, size: 16),
//             label: const Text('复制'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('好的'),
//           ),
//         ],
//         if (_isGenerating && !_hasError)
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('取消'),
//           ),
//       ],
//     );
//   }
// }
