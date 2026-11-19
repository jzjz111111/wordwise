import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorite_word_provider.dart';
import '../providers/new_word_provider.dart';


/// 基础UI部件：按压动效、水波纹、仅图标变色，无常驻背景色块
Widget _buildToggleButtonBase({
  required IconData icon,
  required IconData activeIcon,
  required Color color,
  required bool isActive,
  required VoidCallback onTap,
  required Color bgColor,
  required Color secondaryTextColor,
}) {
  bool isPressed = false;
  return StatefulBuilder(
    builder: (context, setBtnState) {
      return AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            // !!! 删除常驻的状态底色，背景永远透明
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: color.withOpacity(0.20),
              highlightColor: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              onTapDown: (_) => setBtnState(() => isPressed = true),
              onTapUp: (_) => setBtnState(() => isPressed = false),
              onTapCancel: () => setBtnState(() => isPressed = false),
              onTap: onTap,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey<bool>(isActive),
                    // 状态仅控制图标颜色！
                    color: isActive ? color : secondaryTextColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// 收藏切换按钮（独立Consumer，内部监听provider，局部刷新）
class FavoriteToggleButton extends ConsumerWidget {
  final int wordId;
  final VoidCallback? afterToggle;
  final Color bgColor;
  final Color secondaryTextColor;

  const FavoriteToggleButton({
    super.key,
    required this.wordId,
    this.afterToggle,
    this.bgColor = const Color(0xFFF7F8FA),
    this.secondaryTextColor = const Color(0xFF9AA0B4),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isFavoriteProvider(wordId)).value ?? false;
    return _buildToggleButtonBase(
      icon: Icons.star_border_rounded,
      activeIcon: Icons.star,
      color: const Color(0xFFFFB74D),
      isActive: isActive,
      bgColor: bgColor,
      secondaryTextColor: secondaryTextColor,
      onTap: () {
        final cur = ref.read(isFavoriteProvider(wordId)).value ?? false;
        if (cur) {
          ref.read(removeFavoriteProvider(wordId));
        } else {
          ref.read(addFavoriteProvider(wordId));
        }
        afterToggle?.call();
      },
    );
  }
}

/// 生词本切换按钮（独立Consumer）
class NewWordToggleButton extends ConsumerWidget {
  final int wordId;
  final VoidCallback? afterToggle;
  final Color bgColor;
  final Color secondaryTextColor;

  const NewWordToggleButton({
    super.key,
    required this.wordId,
    this.afterToggle,
    this.bgColor = const Color(0xFFF7F8FA),
    this.secondaryTextColor = const Color(0xFF9AA0B4),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isInNewWordProvider(wordId)).value ?? false;
    return _buildToggleButtonBase(
      icon: Icons.label_important_outline,
      activeIcon: Icons.label_important,
      color: const Color(0xFFFF8A75),
      isActive: isActive,
      bgColor: bgColor,
      secondaryTextColor: secondaryTextColor,
      onTap: () {
        final cur = ref.read(isInNewWordProvider(wordId)).value ?? false;
        if (cur) {
          ref.read(removeNewWordProvider(wordId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已移出生词本'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ref.read(addNewWordProvider(wordId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已加入生词本'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        afterToggle?.call();
      },
    );
  }
}