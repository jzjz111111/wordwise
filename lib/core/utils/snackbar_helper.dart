import 'package:flutter/material.dart';

/// 与项目主题统一的 SnackBar
void showAppSnackBar(
    BuildContext context,
    String message, {
      SnackBarType type = SnackBarType.normal,
    }) {
  const accentColor = Color(0xFF8A9EDB);
  const successColor = Color(0xFF81C784);
  const dangerColor = Color(0xFFFF8A75);

  Color? bg;
  switch (type) {
    case SnackBarType.success:
      bg = successColor;
      break;
    case SnackBarType.error:
      bg = dangerColor;
      break;
    case SnackBarType.normal:
      bg = null;   // 用默认色
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}

enum SnackBarType { normal, success, error }