import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../features/study/presentation/providers/study_provider.dart';
import '../../../../core/services/sync_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      if (_isLoginMode) {
        await auth.signIn(_emailController.text, _passwordController.text);
        if (mounted) {
          final wordRepo = ref.read(wordRepositoryProvider);
          await wordRepo.initializeWords();
          final syncService = SyncService();
          await syncService.downloadFromCloud();
          await syncService.downloadWrongWordsFromCloud();
          context.go('/home');
        }
      } else {
        await auth.signUp(_emailController.text, _passwordController.text);
        await auth.signOut();
        if (mounted) {
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('注册成功！请登录')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📚 WordWise',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLoginMode ? '登录' : '注册'),
              ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                setState(() => _isLoginMode = !_isLoginMode);
              },
              child: Text(
                _isLoginMode
                    ? '还没有账号？点击注册'
                    : '已有账号？点击登录',
              ),
            ),
          ],
        ),
      ),
    );
  }
}