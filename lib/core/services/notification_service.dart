import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化通知
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    await _createNotificationChannel();
  }

  /// 创建通知渠道
  Future<void> _createNotificationChannel() async {
    // ✅ 去掉 const，改用 final
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wordwise_channel',
      'WordWise 学习提醒',
      description: '每日复习提醒通知',
      importance: Importance.high,
      enableVibration: true,
      ledColor: Colors.blue,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 检查通知是否已开启
  Future<bool> checkNotificationEnabled() async {
    final bool? enabled = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// 安排每日复习提醒
  Future<void> scheduleDailyReminder(int wordCount) async {
    await _plugin.cancelAll();

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);

    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 测试通知
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
}