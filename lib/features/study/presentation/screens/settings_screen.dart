import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/study_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ====================== 全局配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _successColor = Color(0xFF81C784);

  bool _isNotificationEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final service = NotificationService();
    final enabled = await service.checkNotificationEnabled();
    setState(() {
      _isNotificationEnabled = enabled;
    });
  }

  /// 检查是否有精确闹钟权限
  Future<bool> _hasExactAlarmPermission() async {
    if (await _isAndroid12OrAbove()) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        return true;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _isAndroid12OrAbove() async {
    return true;
  }

  /// 跳转到系统设置，请求精确闹钟权限
  Future<void> _requestExactAlarmPermission() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    } catch (e) {
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:com.wordwise.wordwise',
        );
        await intent.launch();
      } catch (e2) {
        if (mounted) {
          _showManualGuideDialog();
        }
      }
    }
  }

  void _showManualGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '精确闹钟权限说明',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '为了确保每日复习提醒准时送达，请手动前往系统设置授权：\n\n'
              '1. 打开「设置」→「应用」→「WordWise」\n'
              '2. 点击「权限」→「闹钟和提醒」\n'
              '3. 开启「允许设置精确闹钟」',
          style: TextStyle(
            color: _secondaryText,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '我知道了',
              style: TextStyle(color: _accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => _isLoading = true);

    final service = NotificationService();

    if (value) {
      final hasPermission = await service.checkNotificationEnabled();
      if (!hasPermission) {
        setState(() => _isNotificationEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请前往系统设置开启通知权限'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      bool hasExactAlarm = await _hasExactAlarmPermission();
      try {
        await _requestExactAlarmPermission();
        setState(() => _isNotificationEnabled = true);
        final stats = await ref.read(todayStatsProvider.future);
        final count = stats['todayReview'] ?? 0;
        await service.scheduleDailyReminder(count);
      } catch (e) {
        _showManualGuideDialog();
        setState(() => _isNotificationEnabled = false);
      }
    } else {
      await service.cancelAll();
      setState(() => _isNotificationEnabled = false);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Container(
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
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.notifications_active_rounded,
                  title: '每日复习提醒',
                  subtitle: '每天早上8点准时提醒复习',
                  trailing: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accentColor,
                    ),
                  )
                      : Switch(
                    value: _isNotificationEnabled,
                    onChanged: _toggleNotification,
                    activeColor: _accentColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.alarm_rounded,
                  title: '提醒时间',
                  subtitle: '每天 08:00',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText.withOpacity(0.6),
                    size: 20,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('时间设置开发中...'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于精确闹钟',
                  subtitle: '手动授权才能准时送达提醒',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText.withOpacity(0.6),
                    size: 20,
                  ),
                  onTap: () => _showManualGuideDialog(),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: _successColor,
                  iconBgColor: _successColor.withOpacity(0.12),
                  title: '测试通知',
                  subtitle: '点击发送一条测试通知',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText.withOpacity(0.6),
                    size: 20,
                  ),
                  onTap: () async {
                    final service = NotificationService();
                    await service.sendTestNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('测试通知已发送'),
                          backgroundColor: _successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final itemContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor ?? _accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? _accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap == null) return itemContent;

    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.98),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: itemContent,
          ),
        );
      },
    );
  }

  /// 淡色分割线
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey.withOpacity(0.08),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:android_intent_plus/flag.dart';
// import '../../../../core/services/notification_service.dart';
// import '../providers/study_provider.dart';
//
// class SettingsScreen extends ConsumerStatefulWidget {
//   const SettingsScreen({super.key});
//
//   @override
//   ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends ConsumerState<SettingsScreen> {
//   bool _isNotificationEnabled = false;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkNotificationStatus();
//   }
//
//   Future<void> _checkNotificationStatus() async {
//     final service = NotificationService();
//     final enabled = await service.checkNotificationEnabled();
//     setState(() {
//       _isNotificationEnabled = enabled;
//     });
//   }
//
//   /// 检查是否有精确闹钟权限
//   Future<bool> _hasExactAlarmPermission() async {
//     // Android 12+ 才需要检查
//     if (await _isAndroid12OrAbove()) {
//       try {
//         final intent = AndroidIntent(
//           action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
//         );
//         // 检查是否有权限的简单方式：通过 canResolveActivity
//         // 或者直接用 try-catch
//         return true; // 默认返回 true，后续通过请求来引导
//       } catch (e) {
//         return false;
//       }
//     }
//     return true;
//   }
//
//   Future<bool> _isAndroid12OrAbove() async {
//     // 简单判断：Android 12+ (API 31+)
//     // 可以通过 platform channel 获取，这里简化处理
//     return true; // 假设是 Android 12+，实际会走请求流程
//   }
//
//   /// 跳转到系统设置，请求精确闹钟权限
//   Future<void> _requestExactAlarmPermission() async {
//     try {
//       // 方法1：通过 Intent 跳转到系统闹钟权限设置页
//       final AndroidIntent intent = AndroidIntent(
//         action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
//       );
//       await intent.launch();
//     } catch (e) {
//       // 方法2：如果上面的 Intent 不可用，跳转到应用设置页
//       try {
//         final AndroidIntent intent = AndroidIntent(
//           action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
//           data: 'package:com.wordwise.wordwise',
//         );
//         await intent.launch();
//       } catch (e2) {
//         // 兜底：手动引导用户
//         if (mounted) {
//           _showManualGuideDialog();
//         }
//       }
//     }
//   }
//
//   void _showManualGuideDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('需要精确闹钟权限'),
//         content: const Text(
//             '为了确保每日复习提醒准时送达，请手动前往系统设置：\n\n'
//                 '1. 打开「设置」→「应用」→「WordWise」\n'
//                 '2. 点击「权限」→「闹钟和提醒」\n'
//                 '3. 开启「允许设置精确闹钟」'
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('我知道了'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _toggleNotification(bool value) async {
//     setState(() => _isLoading = true);
//
//     final service = NotificationService();
//
//     if (value) {
//       // 1. 检查通知权限
//       final hasPermission = await service.checkNotificationEnabled();
//       if (!hasPermission) {
//         setState(() => _isNotificationEnabled = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('请前往系统设置开启通知权限')),
//           );
//         }
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       // 2. 检查精确闹钟权限（Android 12+）
//       // 尝试请求精确闹钟权限
//       // 注意：这里需要用户手动授权，我们先跳转到设置页引导
//       bool hasExactAlarm = await _hasExactAlarmPermission();
//       // 实际上通过 try-catch 检查，这里我们直接请求
//       try {
//         await _requestExactAlarmPermission();
//         // 跳转后用户可能授权了，但我们需要用户返回后重新点击
//         // 所以这里先保存状态，等用户返回后再验证
//         setState(() => _isNotificationEnabled = true);
//         // 尝试安排通知
//         final stats = await ref.read(todayStatsProvider.future);
//         final count = stats['todayReview'] ?? 0;
//         await service.scheduleDailyReminder(count);
//       } catch (e) {
//         // 如果失败，提示用户手动授权
//         _showManualGuideDialog();
//         setState(() => _isNotificationEnabled = false);
//       }
//     } else {
//       // 关闭通知
//       await service.cancelAll();
//       setState(() => _isNotificationEnabled = false);
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('⚙️ 设置'),
//         centerTitle: true,
//       ),
//       body: ListView(
//         children: [
//           const SizedBox(height: 16),
//           ListTile(
//             leading: const Icon(Icons.notifications_active),
//             title: const Text('每日复习提醒'),
//             subtitle: const Text('每天早上8点准时提醒您复习单词'),
//             trailing: _isLoading
//                 ? const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : Switch(
//               value: _isNotificationEnabled,
//               onChanged: _toggleNotification,
//               activeColor: Colors.blue,
//             ),
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.alarm),
//             title: const Text('提醒时间'),
//             subtitle: const Text('每天 08:00'),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('时间设置开发中...')),
//               );
//             },
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.info_outline),
//             title: const Text('关于精确闹钟'),
//             subtitle: const Text('精确闹钟需要您手动授权才能准时提醒'),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () {
//               _showManualGuideDialog();
//             },
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.check_circle, color: Colors.green),
//             title: const Text('测试通知'),
//             subtitle: const Text('点击发送一条测试通知'),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () async {
//               final service = NotificationService();
//               await service.sendTestNotification();
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('✅ 测试通知已发送')),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }