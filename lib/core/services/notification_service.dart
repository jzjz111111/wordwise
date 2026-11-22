import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 精确闹钟权限缺失时抛出，调用方据此引导用户去系统设置授权
class ExactAlarmPermissionException implements Exception {
  const ExactAlarmPermissionException();
  @override
  String toString() => 'ExactAlarmPermissionException: 未授予精确闹钟权限';
}

/// 每日复习提醒服务
///
/// 核心职责：
/// - 初始化通知渠道（只做一次）
/// - 初始化设备时区（zonedSchedule 依赖，必须，否则会按 UTC 计算时间）
/// - 按用户自选时间注册每日 exact alarm
/// - 持久化 enabled/hour/minute 到 shared_preferences
/// - App 启动 / 设备重启后自动恢复调度
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'wordwise_channel';
  static const _channelName = 'WordWise 学习提醒';
  static const _channelDesc = '每日复习提醒通知';

  // shared_preferences key
  static const _prefsEnabled = 'reminder_enabled';
  static const _prefsHour = 'reminder_hour';
  static const _prefsMinute = 'reminder_minute';

  // 默认值（公开，供 SettingsScreen 引用）
  static const defaultHour = 8;
  static const defaultMinute = 0;

  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// 初始化通知插件 + 时区（只在 App 生命周期内做一次）
  Future<void> init() async {
    if (_initialized) return;

    await _initTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);
    await _createNotificationChannel();
    _initialized = true;
  }

  /// 初始化时区数据，并把 tz.local 设成设备真实时区
  ///
  /// 关键：timezone 包初始化后 tz.local 默认是 UTC。
  /// 不调用 setLocalLocation，用户在 UTC+8 设置 09:00，
  /// 实际会按 09:00 UTC（本地 17:00）注册，晚了整整 8 小时。
  Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();

    String zoneName = 'Asia/Shanghai';
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      zoneName = info.identifier;
    } catch (e) {
      debugPrint('⚠️ 获取设备时区失败，回退 Asia/Shanghai: $e');
    }

    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (e) {
      debugPrint('⚠️ 时区 "$zoneName" 不受支持，回退 Asia/Shanghai: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    debugPrint('📦 [通知] 当前时区: $zoneName (${tz.local.name})');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      ledColor: Colors.blue,
    );

    await _android?.createNotificationChannel(channel);
  }

  /// 检查通知权限是否已开启
  Future<bool> checkNotificationEnabled() async {
    await ensureInitialized();
    final bool? enabled = await _android?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// 请求通知权限（Android 13+ 会弹系统对话框）
  Future<bool> requestNotificationPermission() async {
    await ensureInitialized();
    final granted = await _android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// 跳转系统设置请求精确闹钟权限（Android 12+）
  ///
  /// flutter_local_notifications 17.x 没有"查询"精确闹钟权限的 API，
  /// 只有这个"请求"方法，会打开系统的「闹钟和提醒」设置页。
  Future<void> requestExactAlarmPermission() async {
    await ensureInitialized();
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('⚠️ 打开精确闹钟设置页失败: $e');
    }
  }

  /// 读取用户自选时间
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
  /// [hour] / [minute] 是设备本地时间；[wordCount] 用于动态文案。
  ///
  /// 抛出 [ExactAlarmPermissionException] 表示系统未授予精确闹钟权限。
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    int wordCount = 0,
  }) async {
    await ensureInitialized();
    await _plugin.cancelAll();

    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 今天这个点已经过了 → 排到明天
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('📦 [通知] 计划提醒时间: $scheduled (本地时间 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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

    try {
      await _plugin.zonedSchedule(
        0,
        'WordWise 复习提醒',
        reminderText,
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted') ||
          msg.contains('exact_alarms_not_supported')) {
        throw const ExactAlarmPermissionException();
      }
      rethrow;
    }

    // 调度成功才持久化，避免"显示已开启但实际没排上"
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, true);
    await prefs.setInt(_prefsHour, hour);
    await prefs.setInt(_prefsMinute, minute);
  }

  /// 取消所有提醒，并把 enabled 设为 false
  Future<void> cancelAll() async {
    await ensureInitialized();
    await _plugin.cancel(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, false);
  }

  /// App 启动时 / 设备重启后：如果用户之前开了提醒，按存的时间重新调度
  Future<void> rescheduleIfEnabled({int wordCount = 0}) async {
    await ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsEnabled) ?? false;
    if (!enabled) return;

    final hour = prefs.getInt(_prefsHour) ?? defaultHour;
    final minute = prefs.getInt(_prefsMinute) ?? defaultMinute;
    try {
      await scheduleDailyReminder(
        hour: hour,
        minute: minute,
        wordCount: wordCount,
      );
    } on ExactAlarmPermissionException {
      debugPrint('⚠️ [通知] 恢复调度失败：精确闹钟权限未授予');
    }
  }

  /// 测试通知
  Future<void> sendTestNotification() async {
    await ensureInitialized();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(1, '🧪 测试通知', '通知功能已正常工作！', details);
  }

  /// 延迟 [seconds] 秒后发一条通知，用于验证定时能力
  Future<void> scheduleTestNotificationIn({int seconds = 10}) async {
    await ensureInitialized();

    final granted = await checkNotificationEnabled() ||
        await requestNotificationPermission();
    debugPrint('📦 [通知] 通知权限: $granted');
    if (!granted) {
      throw StateError('通知权限未开启，请到系统设置里允许 WordWise 发送通知');
    }

    final scheduled = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: seconds),
    );

    debugPrint('📦 [通知] 测试通知计划于: $scheduled');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _plugin.zonedSchedule(
        2,
        '🧪 定时测试',
        '$seconds 秒已到，定时通知正常工作',
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('exact_alarms_not_permitted') ||
          msg.contains('exact_alarms_not_supported')) {
        throw const ExactAlarmPermissionException();
      }
      rethrow;
    }
  }

  /// 确保插件已初始化（供内部方法兜底调用）
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}
