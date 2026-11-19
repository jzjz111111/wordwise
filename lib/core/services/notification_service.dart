import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 每日复习提醒服务
///
/// 核心职责：
/// - 初始化通知渠道（只做一次）
/// - 按用户自选时间注册每日 exact alarm
/// - 持久化 enabled/hour/minute 到 shared_preferences
/// - App 启动 / 设备重启后自动恢复调度
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // shared_preferences key
  static const _prefsEnabled = 'reminder_enabled';
  static const _prefsHour = 'reminder_hour';
  static const _prefsMinute = 'reminder_minute';

  // 默认值（公开，供 SettingsScreen 引用）
  static const defaultHour = 8;
  static const defaultMinute = 0;

  bool _initialized = false;

  /// 初始化通知插件（只在 App 生命周期内做一次）
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);
    await _createNotificationChannel();
    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wordwise_channel',
      'WordWise 学习提醒',
      description: '每日复习提醒通知',
      importance: Importance.high,
      enableVibration: true,
      ledColor: Colors.blue,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 检查通知权限是否已开启
  Future<bool> checkNotificationEnabled() async {
    final bool? enabled = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// 检查精确闹钟权限（Android 12+，API 31+）
  ///
  /// 权限缺失时 exactAllowWhileIdle 会静默失效，提醒可能不准点。
  /// 这是 Android 12+ 的安全机制，必须引导用户手动去系统设置里授权。
  ///
  /// 注意：flutter_local_notifications 不同版本的 API 名不完全一致
  /// （有的版本叫 canScheduleExactAlarms，有的版本没有）。
  /// 这里用 dynamic 反射调用，不存在时默认有（引导用户手动去设置）。
  Future<bool> checkExactAlarmPermission() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return true;

      // ignore: avoid_dynamic_calls
      final result = await (androidPlugin as dynamic).canScheduleExactAlarms();
      return result as bool? ?? true;
    } catch (e) {
      return true;
    }
  }

  /// 读取用户自选时间（返回 DateTime 的 hour/minute）
  /// 默认 08:00
  Future<({int hour, int minute})> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_prefsHour) ?? defaultHour,
      minute: prefs.getInt(_prefsMinute) ?? defaultMinute,
    );
  }

  /// 读取提醒是否启用
  Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabled) ?? false;
  }

  /// 安排每日复习提醒
  ///
  /// [hour] / [minute] 决定响铃时间；[wordCount] 用于动态文案。
  /// 调用会先 cancelAll（因为我们只需要一条每日提醒），
  /// 然后按指定时间重新注册。
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    int wordCount = 0,
  }) async {
    await ensureInitialized();
    await _plugin.cancelAll();

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wordwise_channel',
      'WordWise 学习提醒',
      channelDescription: '每日复习提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final reminderText = wordCount > 0
        ? '📚 今日待复习 $wordCount 个单词，开始学习吧！'
        : '📚 坚持每天学习，词汇量自然增长！';

    await _plugin.zonedSchedule(
      0,
      'WordWise 复习提醒',
      reminderText,
      tzScheduledTime,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // 持久化用户设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, true);
    await prefs.setInt(_prefsHour, hour);
    await prefs.setInt(_prefsMinute, minute);
  }

  /// 取消所有提醒，并把 enabled 设为 false
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, false);
  }

  /// App 启动时 / 设备重启后：如果用户之前开了提醒，按存的时间重新调度
  ///
  /// Android 的 exact alarm 在 App force-stop 或设备重启后会被系统清空，
  /// 必须在用户下次打开 App 时手动恢复一次。
  Future<void> rescheduleIfEnabled({int wordCount = 0}) async {
    await ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsEnabled) ?? false;
    if (!enabled) return;

    final hour = prefs.getInt(_prefsHour) ?? defaultHour;
    final minute = prefs.getInt(_prefsMinute) ?? defaultMinute;
    await scheduleDailyReminder(
      hour: hour,
      minute: minute,
      wordCount: wordCount,
    );
  }

  /// 测试通知
  Future<void> sendTestNotification() async {
    await ensureInitialized();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wordwise_channel',
      'WordWise 学习提醒',
      channelDescription: '每日复习提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(1, '🧪 测试通知', '通知功能已正常工作！', details);
  }

  /// 确保插件已初始化（供内部方法兜底调用）
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}
