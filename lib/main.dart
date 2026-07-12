import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/study/presentation/screens/home_screen.dart';
import 'core/router/app_router.dart';
import 'core/database/database_helper.dart';

void main() async{
  // 确保 Widgets 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库并插入示例单词
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.insertInitialWords();
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