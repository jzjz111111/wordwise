import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/spell_test_provider.dart';
import '../../domain/entities/word.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spellTestProvider.notifier).loadWords(widget.words);
    });
  }

  @override
  void dispose() {
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
          onTap: () async {
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
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import '../providers/spell_test_provider.dart';
// import '../../domain/entities/word.dart';
// import 'choice_test_screen.dart';
//
// class SpellTestScreen extends ConsumerStatefulWidget {
//   final List<Word> words;
//   const SpellTestScreen({super.key, required this.words});
//
//   @override
//   ConsumerState<SpellTestScreen> createState() => _SpellTestScreenState();
// }
//
// class _SpellTestScreenState extends ConsumerState<SpellTestScreen> {
//   final FlutterTts _tts = FlutterTts();
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(spellTestProvider.notifier).loadWords(widget.words);
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(spellTestProvider);
//
//     // 核心修改：统一监听状态变化，处理所有自动跳转逻辑
//     ref.listen(spellTestProvider, (previous, current) {
//       // 场景1：测试进入完成状态时跳转（边沿触发：仅从false变true时执行一次）
//       if (current.isCompleted && previous?.isCompleted != true) {
//         _navigateToChoiceTest(current.wrongWords, current.words);
//         return;
//       }
//
//       // 场景2：最后一题提交答案、显示结果时自动跳转
//       final isLastWord = current.currentIndex + 1 >= current.totalCount;
//       final wasLastWord = previous != null
//           ? previous.currentIndex + 1 >= previous.totalCount
//           : false;
//       final justShowResult = current.showResult && previous?.showResult != true;
//       if (isLastWord && justShowResult) {
//         _navigateToChoiceTest(current.wrongWords, current.words);
//       }
//     });
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('✍️ 拼写测试'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: state.isCompleted ? _buildCompletionView() : _buildTestView(state),
//       ),
//     );
//   }
//
//   // 抽取跳转逻辑为独立方法，统一处理、统一加保护
//   void _navigateToChoiceTest(List<Word> wrongWords, List<Word> allWords) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // 生命周期保护：页面已销毁则不执行，避免报错
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ChoiceTestScreen(
//             words: wrongWords.isNotEmpty ? wrongWords : allWords,
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _buildTestView(SpellTestState state) {
//     if (state.words.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     final word = state.currentWord!;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         // 进度
//         Text('${state.currentIndex + 1} / ${state.totalCount}'),
//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: (state.currentIndex + 1) / state.totalCount,
//           backgroundColor: Colors.grey[200],
//           color: Colors.blue,
//         ),
//         const SizedBox(height: 40),
//
//         // 提示区
//         Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey[200]!),
//           ),
//           child: Column(
//             children: [
//               Text(word.meaning, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 12),
//               if (word.phoneticUk != null) Text('英 ${word.phoneticUk}'),
//               const SizedBox(height: 12),
//               IconButton(
//                 onPressed: () => _tts.speak(word.word),
//                 icon: const Icon(Icons.volume_up, size: 36),
//                 color: Colors.blue,
//               ),
//               const Text('👆 点击听发音', style: TextStyle(fontSize: 12, color: Colors.grey)),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 32),
//
//         // 输入框
//         TextField(
//           controller: _controller,
//           focusNode: _focusNode,
//           onChanged: (value) => ref.read(spellTestProvider.notifier).updateInput(value),
//           onSubmitted: (_) {
//             if (!state.showResult) {
//               ref.read(spellTestProvider.notifier).submitAnswer();
//             }
//           },
//           decoration: InputDecoration(
//             hintText: '输入英文...',
//             prefixIcon: const Icon(Icons.edit),
//             suffixIcon: state.showResult
//                 ? Icon(state.isCorrect ? Icons.check_circle : Icons.cancel, color: state.isCorrect ? Colors.green : Colors.red)
//                 : null,
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             enabled: !state.showResult,
//           ),
//           autofocus: true,
//         ),
//
//         const SizedBox(height: 16),
//
//         if (state.showResult) ...[
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: state.isCorrect ? Colors.green[50] : Colors.red[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: state.isCorrect ? Colors.green : Colors.red),
//             ),
//             child: Row(
//               children: [
//                 Icon(state.isCorrect ? Icons.check_circle : Icons.error, color: state.isCorrect ? Colors.green : Colors.red),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(state.isCorrect ? '✅ 正确！' : '❌ 错误', style: TextStyle(fontWeight: FontWeight.bold, color: state.isCorrect ? Colors.green : Colors.red)),
//                       if (!state.isCorrect) Text('正确答案: ${word.word}'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           // 修复：移除了错误的跳转代码，替换为友好的加载提示
//           if (state.currentIndex + 1 >= state.totalCount) ...[
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 12),
//                 child: Text('正在进入下一轮测试...', style: TextStyle(color: Colors.grey)),
//               ),
//             ),
//           ] else ...[
//             // 不是最后一个：显示“下一个”按钮
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   _controller.clear();
//                   _focusNode.requestFocus();
//                   ref.read(spellTestProvider.notifier).nextWord();
//                 },
//                 child: const Text('下一个'),
//               ),
//             ),
//           ],
//         ],
//
//         if (!state.showResult) ...[
//           const Spacer(),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: state.userInput.trim().isEmpty ? null : () async => await ref.read(spellTestProvider.notifier).submitAnswer(),
//               child: const Text('提交答案'),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildCompletionView() {
//     // 修复：移除了跳转代码，只保留加载UI
//     return const Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 16),
//           Text('正在进入下一轮测试...', style: TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }
// }