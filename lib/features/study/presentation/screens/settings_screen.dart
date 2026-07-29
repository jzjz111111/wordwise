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
    // Android 12+ 才需要检查
    if (await _isAndroid12OrAbove()) {
      try {
        final intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        // 检查是否有权限的简单方式：通过 canResolveActivity
        // 或者直接用 try-catch
        return true; // 默认返回 true，后续通过请求来引导
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _isAndroid12OrAbove() async {
    // 简单判断：Android 12+ (API 31+)
    // 可以通过 platform channel 获取，这里简化处理
    return true; // 假设是 Android 12+，实际会走请求流程
  }

  /// 跳转到系统设置，请求精确闹钟权限
  Future<void> _requestExactAlarmPermission() async {
    try {
      // 方法1：通过 Intent 跳转到系统闹钟权限设置页
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    } catch (e) {
      // 方法2：如果上面的 Intent 不可用，跳转到应用设置页
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:com.wordwise.wordwise',
        );
        await intent.launch();
      } catch (e2) {
        // 兜底：手动引导用户
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
        title: const Text('需要精确闹钟权限'),
        content: const Text(
            '为了确保每日复习提醒准时送达，请手动前往系统设置：\n\n'
                '1. 打开「设置」→「应用」→「WordWise」\n'
                '2. 点击「权限」→「闹钟和提醒」\n'
                '3. 开启「允许设置精确闹钟」'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => _isLoading = true);

    final service = NotificationService();

    if (value) {
      // 1. 检查通知权限
      final hasPermission = await service.checkNotificationEnabled();
      if (!hasPermission) {
        setState(() => _isNotificationEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请前往系统设置开启通知权限')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. 检查精确闹钟权限（Android 12+）
      // 尝试请求精确闹钟权限
      // 注意：这里需要用户手动授权，我们先跳转到设置页引导
      bool hasExactAlarm = await _hasExactAlarmPermission();
      // 实际上通过 try-catch 检查，这里我们直接请求
      try {
        await _requestExactAlarmPermission();
        // 跳转后用户可能授权了，但我们需要用户返回后重新点击
        // 所以这里先保存状态，等用户返回后再验证
        setState(() => _isNotificationEnabled = true);
        // 尝试安排通知
        final stats = await ref.read(todayStatsProvider.future);
        final count = stats['todayReview'] ?? 0;
        await service.scheduleDailyReminder(count);
      } catch (e) {
        // 如果失败，提示用户手动授权
        _showManualGuideDialog();
        setState(() => _isNotificationEnabled = false);
      }
    } else {
      // 关闭通知
      await service.cancelAll();
      setState(() => _isNotificationEnabled = false);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('每日复习提醒'),
            subtitle: const Text('每天早上8点准时提醒您复习单词'),
            trailing: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Switch(
              value: _isNotificationEnabled,
              onChanged: _toggleNotification,
              activeColor: Colors.blue,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('提醒时间'),
            subtitle: const Text('每天 08:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('时间设置开发中...')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于精确闹钟'),
            subtitle: const Text('精确闹钟需要您手动授权才能准时提醒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showManualGuideDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('测试通知'),
            subtitle: const Text('点击发送一条测试通知'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final service = NotificationService();
              await service.sendTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ 测试通知已发送')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}