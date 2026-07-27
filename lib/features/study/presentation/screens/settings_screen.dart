import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // 这里简化处理，假设默认开启
    setState(() {
      _isNotificationEnabled = true;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => _isLoading = true);

    final service = NotificationService();

    if (value) {
      // 开启通知
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

      // 获取今日待复习数量
      try {
        final stats = await ref.read(todayStatsProvider.future);
        final count = stats['todayReview'] ?? 0;
        await service.scheduleDailyReminder(count);
        setState(() => _isNotificationEnabled = true);
      } catch (e) {
        // 如果数据还没加载好，默认0
        await service.scheduleDailyReminder(0);
        setState(() => _isNotificationEnabled = true);
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
            subtitle: const Text('每天早上8点提醒您复习单词'),
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
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('测试通知'),
            subtitle: const Text('点击发送一条测试通知'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final service = NotificationService();
              await service.sendTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 测试通知已发送')),
              );
            },
          ),
        ],
      ),
    );
  }
}