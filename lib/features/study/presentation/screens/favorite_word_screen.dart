import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorite_word_provider.dart';
import '../../domain/entities/word.dart';
import '../widgets/word_toggle_button.dart';
import '../../../../core/services/tts_service.dart';

class FavoriteWordScreen extends ConsumerStatefulWidget {
  const FavoriteWordScreen({super.key});

  @override
  ConsumerState<FavoriteWordScreen> createState() => _FavoriteWordScreenState();
}

class _FavoriteWordScreenState extends ConsumerState<FavoriteWordScreen> {
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final favoriteAsync = ref.watch(favoriteWordListProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '收藏本',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: favoriteAsync.when(
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
          GestureDetector(
            onTap: () => TtsService.instance.speak(word.word),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.volume_up_outlined,
                color: _accentColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FavoriteToggleButton(
            wordId: word.id!,
            bgColor: _cardColor,
            secondaryTextColor: _secondaryText,
            afterToggle: () {
              // 取消收藏之后，让收藏列表provider失效刷新页面列表
              ref.invalidate(favoriteWordListProvider);
            },
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 64,
            color: _secondaryText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无收藏',
            style: TextStyle(fontSize: 16, color: _secondaryText),
          ),
          const SizedBox(height: 8),
          Text(
            '点击单词卡片的收藏按钮即可添加',
            style: TextStyle(fontSize: 13, color: _secondaryText.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}