import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_intent_plus/android_intent.dart';
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
  int _reminderHour = NotificationService.defaultHour;
  int _reminderMinute = NotificationService.defaultMinute;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final service = NotificationService();
    final enabled = await service.getEnabled();
    final time = await service.getSavedTime();
    if (!mounted) return;
    setState(() {
      _isNotificationEnabled = enabled;
      _reminderHour = time.hour;
      _reminderMinute = time.minute;
    });
  }

  String get _reminderTimeLabel {
    final h = _reminderHour.toString().padLeft(2, '0');
    final m = _reminderMinute.toString().padLeft(2, '0');
    return '每天 $h:$m';
  }

  /// 跳转系统设置，请求精确闹钟权限（Android 12+）
  Future<void> _requestExactAlarmPermission() async {
    try {
      const intent = AndroidIntent(
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
        if (mounted) _showManualGuideDialog();
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

  /// 开关每日提醒
  Future<void> _toggleNotification(bool value) async {
    setState(() => _isLoading = true);
    final service = NotificationService();

    if (value) {
      // 1. 检查通知权限
      final hasNotifyPerm = await service.checkNotificationEnabled();
      if (!hasNotifyPerm) {
        if (mounted) {
          _showErrorSnack('请前往系统设置开启通知权限');
        }
        setState(() {
          _isNotificationEnabled = false;
          _isLoading = false;
        });
        return;
      }

      // 2. 检查精确闹钟权限（Android 12+）
      final hasExactAlarm = await service.checkExactAlarmPermission();
      if (!hasExactAlarm) {
        if (mounted) {
          _showNeedExactAlarmDialog(service);
        }
        setState(() {
          _isNotificationEnabled = false;
          _isLoading = false;
        });
        return;
      }

      // 3. 调度
      try {
        final stats = await ref.read(todayStatsProvider.future);
        final count = stats['todayReview'] ?? 0;
        await service.scheduleDailyReminder(
          hour: _reminderHour,
          minute: _reminderMinute,
          wordCount: count,
        );
        if (mounted) {
          setState(() => _isNotificationEnabled = true);
          _showSuccessSnack('提醒已开启，$_reminderTimeLabel 准时送达');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnack('设置提醒失败，请稍后重试');
        }
      }
    } else {
      await service.cancelAll();
      if (mounted) setState(() => _isNotificationEnabled = false);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// 精确闹钟未授权时弹引导弹窗
  void _showNeedExactAlarmDialog(NotificationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '需要精确闹钟权限',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '系统要求手动授权「精确闹钟」才能保证提醒准时送达。\n\n'
          '点击下方按钮前往设置开启，开启后回来重新打开开关即可。',
          style: TextStyle(
            color: _secondaryText,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestExactAlarmPermission();
            },
            child: const Text('前往设置', style: TextStyle(color: _accentColor)),
          ),
        ],
      ),
    );
  }

  /// 时间选择
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accentColor,
            onPrimary: Colors.white,
            surface: _cardColor,
            onSurface: _primaryText,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });

    // 如果开关已经打开，改时间后立刻重新调度
    if (_isNotificationEnabled) {
      final service = NotificationService();
      try {
        final stats = await ref.read(todayStatsProvider.future);
        final count = stats['todayReview'] ?? 0;
        await service.scheduleDailyReminder(
          hour: _reminderHour,
          minute: _reminderMinute,
          wordCount: count,
        );
        if (mounted) {
          _showSuccessSnack('提醒时间已更新为 $_reminderTimeLabel');
        }
      } catch (e) {
        if (mounted) _showErrorSnack('更新提醒时间失败');
      }
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                  subtitle: _isNotificationEnabled
                      ? '已开启，$_reminderTimeLabel 准时送达'
                      : '关闭中',
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
                  icon: Icons.schedule_rounded,
                  title: '提醒时间',
                  subtitle: _reminderTimeLabel,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText.withOpacity(0.6),
                    size: 20,
                  ),
                  onTap: _pickReminderTime,
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
                    if (mounted) _showSuccessSnack('测试通知已发送');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
