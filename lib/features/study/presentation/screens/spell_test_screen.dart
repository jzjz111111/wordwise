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

    // 核心修改：统一监听状态变化，处理所有自动跳转逻辑
    ref.listen(spellTestProvider, (previous, current) {
      // 场景1：测试进入完成状态时跳转（边沿触发：仅从false变true时执行一次）
      if (current.isCompleted && previous?.isCompleted != true) {
        _navigateToChoiceTest(current.wrongWords, current.words);
        return;
      }

      // 场景2：最后一题提交答案、显示结果时自动跳转
      final isLastWord = current.currentIndex + 1 >= current.totalCount;
      final wasLastWord = previous != null
          ? previous.currentIndex + 1 >= previous.totalCount
          : false;
      final justShowResult = current.showResult && previous?.showResult != true;
      if (isLastWord && justShowResult) {
        _navigateToChoiceTest(current.wrongWords, current.words);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ 拼写测试'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: state.isCompleted ? _buildCompletionView() : _buildTestView(state),
      ),
    );
  }

  // 抽取跳转逻辑为独立方法，统一处理、统一加保护
  void _navigateToChoiceTest(List<Word> wrongWords, List<Word> allWords) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 生命周期保护：页面已销毁则不执行，避免报错
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
      return const Center(child: CircularProgressIndicator());
    }

    final word = state.currentWord!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 进度
        Text('${state.currentIndex + 1} / ${state.totalCount}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (state.currentIndex + 1) / state.totalCount,
          backgroundColor: Colors.grey[200],
          color: Colors.blue,
        ),
        const SizedBox(height: 40),

        // 提示区
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Text(word.meaning, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (word.phoneticUk != null) Text('英 ${word.phoneticUk}'),
              const SizedBox(height: 12),
              IconButton(
                onPressed: () => _tts.speak(word.word),
                icon: const Icon(Icons.volume_up, size: 36),
                color: Colors.blue,
              ),
              const Text('👆 点击听发音', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 输入框
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) => ref.read(spellTestProvider.notifier).updateInput(value),
          onSubmitted: (_) {
            if (!state.showResult) {
              ref.read(spellTestProvider.notifier).submitAnswer();
            }
          },
          decoration: InputDecoration(
            hintText: '输入英文...',
            prefixIcon: const Icon(Icons.edit),
            suffixIcon: state.showResult
                ? Icon(state.isCorrect ? Icons.check_circle : Icons.cancel, color: state.isCorrect ? Colors.green : Colors.red)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabled: !state.showResult,
          ),
          autofocus: true,
        ),

        const SizedBox(height: 16),

        if (state.showResult) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: state.isCorrect ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: state.isCorrect ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(state.isCorrect ? Icons.check_circle : Icons.error, color: state.isCorrect ? Colors.green : Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.isCorrect ? '✅ 正确！' : '❌ 错误', style: TextStyle(fontWeight: FontWeight.bold, color: state.isCorrect ? Colors.green : Colors.red)),
                      if (!state.isCorrect) Text('正确答案: ${word.word}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 修复：移除了错误的跳转代码，替换为友好的加载提示
          if (state.currentIndex + 1 >= state.totalCount) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('正在进入下一轮测试...', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ] else ...[
            // 不是最后一个：显示“下一个”按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _controller.clear();
                  _focusNode.requestFocus();
                  ref.read(spellTestProvider.notifier).nextWord();
                },
                child: const Text('下一个'),
              ),
            ),
          ],
        ],

        if (!state.showResult) ...[
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.userInput.trim().isEmpty ? null : () async => await ref.read(spellTestProvider.notifier).submitAnswer(),
              child: const Text('提交答案'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionView() {
    // 修复：移除了跳转代码，只保留加载UI
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在进入下一轮测试...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}