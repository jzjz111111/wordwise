import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorite_word_provider.dart';
import '../providers/new_word_provider.dart';


/// 基础UI部件：按压缩放 + 水波纹 + 选中态用浅色底和实心图标区分
class _ToggleButtonBase extends StatefulWidget {
  const _ToggleButtonBase({
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.isActive,
    required this.onTap,
    required this.secondaryTextColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final Color secondaryTextColor;

  @override
  State<_ToggleButtonBase> createState() => _ToggleButtonBaseState();
}

class _ToggleButtonBaseState extends State<_ToggleButtonBase> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // 选中：主题色浅底；未选中：透明
          color: widget.isActive
              ? widget.color.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: widget.color.withOpacity(0.20),
            highlightColor: widget.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.icon,
                  key: ValueKey<bool>(widget.isActive),
                  color: widget.isActive
                      ? widget.color
                      : widget.secondaryTextColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return _ToggleButtonBase(
      icon: Icons.star_border_rounded,
      activeIcon: Icons.star,
      color: const Color(0xFFFFB74D),
      isActive: isActive,
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
    return _ToggleButtonBase(
      icon: Icons.label_important_outline,
      activeIcon: Icons.label_important,
      color: const Color(0xFFFF8A75),
      isActive: isActive,
      secondaryTextColor: secondaryTextColor,
      onTap: () {
        final cur = ref.read(isInNewWordProvider(wordId)).value ?? false;
        if (cur) {
          ref.read(removeNewWordProvider(wordId));
        } else {
          ref.read(addNewWordProvider(wordId));
        }
        afterToggle?.call();
      },
    );
  }
}