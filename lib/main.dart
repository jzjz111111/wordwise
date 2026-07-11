import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/main.dart';
import 'core/router/app_router.dart';

void main(){
  // ProviderScope 是 Riverpod 的状态容器，它会在内存中创建一个“状态树”，所有 Provider 的数据都存储在这里
  runApp(const ProviderScope(child: MyApp()));

}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){

    // MaterialApp.router是专门配合GoRouter使用的入口
    // 把 appRouter 传进 routerConfig，GoRouter 就接管了所有路由
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