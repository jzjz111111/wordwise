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
        child: state.isCompleted ? _buildCompletionView(state) : _buildTestView(state),
      ),
    );
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _controller.clear();
                _focusNode.requestFocus();
                ref.read(spellTestProvider.notifier).nextWord();
              },
              child: Text(state.currentIndex + 1 >= state.totalCount ? '查看结果' : '下一个'),
            ),
          ),
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

  Widget _buildCompletionView(SpellTestState state) {
    final correct = state.totalCount - state.wrongWords.length;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(state.wrongWords.isEmpty ? Icons.celebration : Icons.sentiment_neutral, size: 72, color: state.wrongWords.isEmpty ? Colors.green : Colors.orange),
          const SizedBox(height: 16),
          Text(state.wrongWords.isEmpty ? '🎉 全部正确！' : '✍️ 拼写完成', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('正确: $correct / ${state.totalCount}'),
          if (state.wrongWords.isNotEmpty) Text('错词: ${state.wrongWords.length} 个', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.wrongWords.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    // 跳转到选择题测试，只传错词
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChoiceTestScreen(
                          words: state.wrongWords,
                        ),
                      ),
                    );
                  },
                  child: const Text('🔁 错词强化'),
                ),
              if (state.wrongWords.isNotEmpty) const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}