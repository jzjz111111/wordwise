import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/spell_test_provider.dart';
import '../../domain/entities/word.dart';
import '../providers/study_provider.dart';
import '../providers/study_stats_provider.dart';
import 'choice_test_screen.dart';

class SpellTestScreen extends ConsumerStatefulWidget {
  final List<Word> words;

  const SpellTestScreen({super.key, required this.words});

  @override
  ConsumerState<SpellTestScreen> createState() => _SpellTestScreenState();
}

class _SpellTestScreenState extends ConsumerState<SpellTestScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _ttsInitialized = false;          // 标记是否初始化完成
  Future<void>? _ttsInitFuture;          // 保存初始化 Future

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
    _ttsInitFuture = _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spellTestProvider.notifier).loadWords(widget.words);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spellTestProvider);

    ref.listen(spellTestProvider, (previous, current) {
      if (current.isCompleted && previous?.isCompleted != true) {
        _navigateToChoiceTest(current.wrongWords, current.words);
        return;
      }

      final isLastWord = current.currentIndex + 1 >= current.totalCount;
      final justShowResult = current.showResult && previous?.showResult != true;
      if (isLastWord && justShowResult) {
        _navigateToChoiceTest(current.wrongWords, current.words);
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
          state.isCompleted ? '完成中' : '拼写测试',
          style: const TextStyle(
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
              ? _buildCompletionView()
              : _buildTestView(state),
        ),
      ),
    );
  }

  void _navigateToChoiceTest(List<Word> wrongWords, List<Word> allWords) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(todayStatsProvider);
      ref.invalidate(totalStudyStatsProvider);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChoiceTestScreen(
            words: wrongWords.isNotEmpty ? wrongWords : allWords,
          ),
        ),
      );
    });
  }

  Widget _buildTestView(SpellTestState state) {
    if (state.words.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      );
    }

    final word = state.currentWord!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressHeader(state),
        const SizedBox(height: 32),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildMeaningCard(word, state),
                const SizedBox(height: 24),
                _buildInputField(state),
                if (state.showResult) ...[
                  const SizedBox(height: 16),
                  _buildResultCard(state, word),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        _buildBottomButton(state),
      ],
    );
  }

  Widget _buildProgressHeader(SpellTestState state) {
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

  Widget _buildMeaningCard(Word word, SpellTestState state) {
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
          // 在 _buildTtsButton 的 onTap 中
          onTap: () async {
            debugPrint('播放按钮被点击，单词: ${word.word}');
            try {
              if (_ttsInitFuture != null && !_ttsInitialized) {
                await _ttsInitFuture;   // 等待初始化完成
              }
              if (!_ttsInitialized) {
                // 初始化失败，提示用户
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('语音引擎未就绪，请检查系统 TTS 设置')),
                  );
                }
                return;
              }
              await _tts.stop();        // 停止之前的播放
              await _tts.speak(word.word);
            } catch (e) {
              debugPrint('TTS 播放失败: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('语音播放失败，请稍后重试')),
                );
              }
            }
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

  Widget _buildInputField(SpellTestState state) {
    return Container(
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
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) => ref.read(spellTestProvider.notifier).updateInput(value),
        onSubmitted: (_) {
          if (!state.showResult) {
            ref.read(spellTestProvider.notifier).submitAnswer();
          }
        },
        autofocus: true,
        enabled: !state.showResult,
        style: const TextStyle(
          fontSize: 16,
          color: _primaryText,
        ),
        decoration: InputDecoration(
          hintText: '输入英文单词',
          hintStyle: const TextStyle(color: _secondaryText),
          prefixIcon: const Icon(Icons.edit_outlined, color: _accentColor),
          suffixIcon: state.showResult
              ? Icon(
            state.isCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: state.isCorrect ? _correctColor : _wrongColor,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _accentColor),
          ),
          filled: true,
          fillColor: _cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildResultCard(SpellTestState state, Word word) {
    final isCorrect = state.isCorrect;

    return AnimatedOpacity(
      opacity: state.showResult ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCorrect ? _correctColor.withOpacity(0.08) : _wrongColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCorrect
                ? _correctColor.withOpacity(0.3)
                : _wrongColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: isCorrect ? _correctColor : _wrongColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? '回答正确' : '回答错误',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCorrect ? _correctColor : _wrongColor,
                    ),
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: 4),
                    Text(
                      '正确答案：${word.word}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(SpellTestState state) {
    final isLastWord = state.currentIndex + 1 >= state.totalCount;

    if (!state.showResult) {
      return StatefulBuilder(
        builder: (context, setBtnState) {
          double scale = 1.0;
          return GestureDetector(
            onTapDown: (_) => setBtnState(() => scale = 0.96),
            onTapUp: (_) => setBtnState(() => scale = 1.0),
            onTapCancel: () => setBtnState(() => scale = 1.0),
            onTap: state.userInput.trim().isEmpty
                ? null
                : () async {
              await ref.read(spellTestProvider.notifier).submitAnswer();
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: state.userInput.trim().isEmpty
                      ? _secondaryText
                      : _accentColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: state.userInput.trim().isEmpty
                      ? null
                      : [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '提交答案',
                  style: TextStyle(
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
      );
    }

    if (isLastWord) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _accentBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '正在进入下一轮测试...',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.96),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () {
            _controller.clear();
            _focusNode.requestFocus();
            ref.read(spellTestProvider.notifier).nextWord();
          },
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
              child: const Text(
                '下一个',
                style: TextStyle(
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
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text(
            '正在进入下一轮测试...',
            style: TextStyle(color: _secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _initTts() async {
    print('🔄 开始初始化 TTS...');
    try {
      final isEnUSAvailable = await _tts.isLanguageAvailable('en-US');
      if (isEnUSAvailable) {
        await _tts.setLanguage('en-US');
      } else {
        final isEnGBAvailable = await _tts.isLanguageAvailable('en-GB');
        if (isEnGBAvailable) {
          await _tts.setLanguage('en-GB');
        } else {
          debugPrint('⚠️ 设备未安装英语语音包，使用默认语言播放');
        }
      }

      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _ttsInitialized = true;

      // 修改：用 getLanguages 查看已安装语言（可选）
      final languages = await _tts.getLanguages;
      debugPrint('✅ TTS 初始化完成，可用语言: $languages');
    } catch (e) {
      debugPrint('❌ TTS 初始化失败: $e');
      _ttsInitialized = false;
    }
  }
}
