import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/choice_test_provider.dart';
import '../providers/study_provider.dart';
import '../../domain/entities/word.dart';

class ChoiceTestScreen extends ConsumerStatefulWidget {
  final List<Word> words;
  const ChoiceTestScreen({super.key, required this.words});

  @override
  ConsumerState<ChoiceTestScreen> createState() => _ChoiceTestScreenState();
}

class _ChoiceTestScreenState extends ConsumerState<ChoiceTestScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 异步回调增加生命周期保护，避免页面销毁后执行报错
      if (!mounted) return;
      final allWords = _getAllWords();
      ref.read(choiceTestProvider.notifier).loadWords(widget.words, allWords);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // 抽取公共方法：获取全量单词，消除重复代码
  List<Word> _getAllWords() {
    return ref.read(todayWordsProvider).maybeWhen(
      data: (words) => words,
      orElse: () => <Word>[],
    );
  }

  // 统一处理测试完成逻辑
  void _handleCompleted(List<Word> wrongWords) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (wrongWords.isNotEmpty) {
        // 有错词：原地重置状态，开始下一轮错词测试（无跳转动画，更流畅）
        final allWords = _getAllWords();
        ref.read(choiceTestProvider.notifier).loadWords(wrongWords, allWords);
      }
      // 无错词：什么都不用做，UI 自动展示完成页
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(choiceTestProvider);

    // ✅ 正确位置：ref.listen 必须放在 build 方法内部
    ref.listen<ChoiceTestState>(choiceTestProvider, (previous, current) {
      // 仅在 isCompleted 刚变为 true 时执行一次（边沿触发）
      if (current.isCompleted && previous?.isCompleted != true) {
        _handleCompleted(current.wrongWords);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 选择题测试'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: state.isCompleted
            ? _buildCompletionView(state)
            : _buildTestView(state),
      ),
    );
  }

  Widget _buildTestView(ChoiceTestState state) {
    if (state.words.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final word = state.currentWord;
    // 空值保护，避免崩溃
    if (word == null) {
      return const Center(child: Text('加载单词失败'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 进度
          Text('${state.currentIndex + 1} / ${state.totalCount}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.totalCount > 0
                ? (state.currentIndex + 1) / state.totalCount
                : 0,
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
                Text(
                  word.meaning,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (word.phoneticUk != null) Text('英 ${word.phoneticUk}'),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () => _tts.speak(word.word),
                  icon: const Icon(Icons.volume_up, size: 36),
                  color: Colors.blue,
                ),
                const Text('点击听发音',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 四个选项
          ...List.generate(4, (index) {
            final isSelected = state.selectedIndex == index;
            final isCorrectOption =
                state.showResult && state.options[index] == word.word;
            final isWrongOption = state.showResult && isSelected && !isCorrectOption;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.showResult
                      ? null
                      : () {
                    final allWords = _getAllWords();
                    ref
                        .read(choiceTestProvider.notifier)
                        .selectAnswer(index, allWords);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: state.showResult
                        ? isCorrectOption
                        ? Colors.green
                        : isWrongOption
                        ? Colors.red
                        : Colors.grey[300]
                        : Colors.grey[100],
                    foregroundColor:
                    state.showResult ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: state.showResult
                            ? isCorrectOption
                            ? Colors.green
                            : isWrongOption
                            ? Colors.red
                            : Colors.transparent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    state.options[index],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // 反馈信息 + 下一个按钮
          if (state.showResult) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.isCorrect ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isCorrect ? Icons.check_circle : Icons.error,
                    color: state.isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.isCorrect
                          ? '正确！'
                          : '错误，正确答案是 ${word.word}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                        state.isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final allWords = _getAllWords();
                  ref.read(choiceTestProvider.notifier).nextWord(allWords);
                },
                child: Text(
                  state.currentIndex + 1 >= state.totalCount
                      ? '查看结果'
                      : '下一题',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionView(ChoiceTestState state) {
    // 有错词：正在加载下一轮
    if (state.wrongWords.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在进入错词重测...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 全部正确 → 显示完成页
    final correct = state.totalCount - state.wrongWords.length;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 72, color: Colors.green),
          const SizedBox(height: 16),
          const Text('全部完成！',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('正确: $correct / ${state.totalCount}',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }
}