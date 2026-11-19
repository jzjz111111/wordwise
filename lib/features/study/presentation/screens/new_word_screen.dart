import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/new_word_provider.dart';
import '../../domain/entities/word.dart';
import '../widgets/word_toggle_button.dart';
import '../../../../core/services/tts_service.dart';

class NewWordScreen extends ConsumerStatefulWidget {
  const NewWordScreen({super.key});

  @override
  ConsumerState<NewWordScreen> createState() => _NewWordScreenState();
}

class _NewWordScreenState extends ConsumerState<NewWordScreen> {
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);

  @override
  Widget build(BuildContext context) {
    final newWordAsync = ref.watch(newWordListProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '生词本',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: newWordAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: words.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildWordItem(words[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
        ),
        error: (err, stack) => Center(
          child: Text('加载失败: $err', style: const TextStyle(color: _secondaryText)),
        ),
      ),
    );
  }

  Widget _buildWordItem(Word word) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.meaning,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 🔊 发音按钮
          _buildSpeakButton(word.word),
          const SizedBox(width: 8),
          NewWordToggleButton(
            wordId: word.id!,
            bgColor: _cardColor,
            secondaryTextColor: _secondaryText,
            afterToggle: () {
              ref.invalidate(newWordListProvider);
            },
          )
        ],
      ),
    );
  }

  /// 列表项发音小按钮
  Widget _buildSpeakButton(String wordText) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.88),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () => TtsService.instance.speak(wordText),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: _secondaryText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无生词',
            style: TextStyle(fontSize: 16, color: _secondaryText),
          ),
          const SizedBox(height: 8),
          Text(
            '学习中答错的单词会自动加入这里',
            style: TextStyle(fontSize: 13, color: _secondaryText.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}