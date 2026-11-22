import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/database_helper.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/tts_service.dart';

/// 全局导航 key，供 Provider / Service 里拿到 BuildContext 弹 Toast 等
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ProviderScope(child: _AppInitializer()));
}

/// 把耗时初始化放到首帧之后执行，避免冷启动黑屏
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doInitialize();
    });
  }

  Future<void> _doInitialize() async {
    const tag = '📦 [Init]';
    debugPrint('$tag 开始初始化...');

    // 先加载 .env（AI Key、模型名等），失败不影响启动
    await Env.load();

    // 只有 Supabase 需要阻塞（登录态依赖它）
    debugPrint('$tag Step 1: Supabase');
    try {
      await Supabase.initialize(
        url: 'https://pniieotfzaanzivseezv.supabase.co',
        publishableKey: 'sb_publishable_ssNHQGrExztJoWrjh4FPMg_8Gc1sJ9B',
      ).timeout(const Duration(seconds: 8));
      debugPrint('$tag ✅ Supabase OK');
    } catch (e) {
      debugPrint('$tag ⚠️ Supabase 失败: $e');
    }

    // Supabase 一就绪就切界面，数据库/通知/TTS 全部后台跑
    if (mounted) {
      setState(() => _initialized = true);
      debugPrint('$tag 界面已切换，后续初始化后台进行');
    }

    // ====== 下面全部 fire-and-forget，不阻塞 ======
    // SQLHelper.instance.database 本身就是 getter，首次 query 时会自动 open，
    // 这里 pre-open 只是为了让第一次查询稍快一点，不阻塞启动
    DatabaseHelper.instance.database.then((_) {
      debugPrint('$tag ✅ 数据库 pre-open 完成');
    }).catchError((e) => debugPrint('$tag ⚠️ 数据库失败: $e'));

    // ColorOS / MIUI 通知权限请求可能永久卡住，绝对不能 await
    NotificationService().init().then((_) {
      // init 完成后，如果用户之前开了提醒，按存储的时间重新调度
      // （App force-stop 或设备重启后 exact alarm 会被清，需要恢复）
      NotificationService().rescheduleIfEnabled().catchError((e) {
        debugPrint('$tag ⚠️ 通知恢复调度失败: $e');
      });
    }).catchError((e) {
      debugPrint('$tag ⚠️ 通知失败: $e');
    });
    TtsService.instance.init().catchError((e) => debugPrint('$tag ⚠️ TTS 失败: $e'));
  }

  @override
  Widget build(BuildContext context) {
    // 初始化期间显示 MyApp（GoRouter 会按 auth 状态跳到 login 或 home），
    // 这样即使还没初始化完，界面也是可见的而不是黑屏。
    if (!_initialized) {
      // 先用 MaterialApp 提供一个 loading 容器，等初始化完再换 MyApp
      return const _SplashScreen();
    }
    return const MyApp();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A9EDB)),
                ),
              ),
              SizedBox(height: 16),
              Text('WordWise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF8A9EDB))),
            ],
          ),
        ),
      ),
    );
  }
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