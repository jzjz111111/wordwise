import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //初始化 Supabase（硬编码）
  await Supabase.initialize(
    url: 'https://pniieotfzaanzivseezv.supabase.co',
    publishableKey: 'sb_publishable_ssNHQGrExztJoWrjh4FPMg_8Gc1sJ9B',  //  用 publishableKey 替代 anonKey
  );

  // 初始化通知
  final notificationService = NotificationService();
  await notificationService.init();

  // 初始化数据库
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WordWise 背单词',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}