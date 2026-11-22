import 'package:go_router/go_router.dart';
import '../../main.dart' show rootNavigatorKey;
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/study/presentation/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);