import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/word_importer.dart';
import '../../../study/presentation/providers/favorite_word_provider.dart';
import '../../../study/presentation/providers/new_word_provider.dart';
import '../../../study/presentation/providers/study_stats_provider.dart';
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

  String? _emailError;
  String? _passwordError;
  // 邮箱正则
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // 与单词详情统一的 INS 极简配色
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _warningColor = Color(0xFFFF8A75);


  bool _validateForm() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = '请输入邮箱');
      return false;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = '邮箱格式不正确');
      return false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = '请输入密码');
      return false;
    }
    if (password.length < 6) {
      setState(() => _passwordError = '密码至少6位字符');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      if (_isLoginMode) {
        await auth.signIn(_emailController.text, _passwordController.text);
        if (mounted) {
          final db = await DatabaseHelper.instance.database;
          final syncService = SyncService();
          await syncService.downloadFromCloud();
          await syncService.downloadWrongWordsFromCloud();
          await syncService.downloadNewWordsFromCloud();
          await syncService.downloadFavoritesFromCloud();

          ref.invalidate(todayStatsProvider);
          ref.invalidate(todayWordsProvider);
          ref.invalidate(dailyStudyStatsProvider);
          ref.invalidate(masteryDistributionProvider);
          ref.invalidate(totalStudyStatsProvider);
          ref.invalidate(newWordListProvider);
          ref.invalidate(favoriteWordListProvider);

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
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.message == 'User already registered') {
            _emailError = '该邮箱已被注册';
          } else if (e.message == 'Invalid login credentials') {
            _passwordError = '邮箱或密码不正确';
          } else if (e.message == 'Password should be at least 6 characters') {
            _passwordError = '密码至少6位字符';
          } else if (e.message == 'invalid email') {
            _emailError = '邮箱格式不正确';
          } else {
            // 其它认证错误用snackbar
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
          }
        });
      }
    } catch (e) {
      // 网络等非Auth异常，保留snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请求失败：$e')));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogo(),
                const SizedBox(height: 48),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildModeSwitch(),
                      const SizedBox(height: 24),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 8),
                      _buildToggleText(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 顶部 Logo 区域
  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'WordWise',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _primaryText,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '智慧背单词',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // 通用卡片容器
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: child,
    );
  }

  // 登录/注册模式切换（胶囊分段控件）
  Widget _buildModeSwitch() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _accentBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLoginMode = true;
                // 切换模式清空错误提示
                _emailError = null;
                _passwordError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isLoginMode
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '登录',
                  style: TextStyle(
                    color: _isLoginMode ? _accentColor : _secondaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLoginMode = false;
                // 切换模式清空错误提示
                _emailError = null;
                _passwordError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isLoginMode
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '注册',
                  style: TextStyle(
                    color: !_isLoginMode ? _accentColor : _secondaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 邮箱输入框
  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: _primaryText, fontSize: 15),
      onChanged: (_) => setState(() => _emailError = null),
      decoration: InputDecoration(
        labelText: '邮箱',
        labelStyle: const TextStyle(color: _secondaryText),
        prefixIcon: const Icon(Icons.email_outlined, color: _accentColor),
        filled: true,
        fillColor: _bgColor,
        errorText: _emailError,
        errorStyle: TextStyle(color: _warningColor, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _warningColor, width:1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _warningColor, width:1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // 密码输入框
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      style: const TextStyle(color: _primaryText, fontSize: 15),
      onChanged: (_) => setState(() => _passwordError = null),
      decoration: InputDecoration(
        labelText: '密码',
        labelStyle: const TextStyle(color: _secondaryText),
        prefixIcon: const Icon(Icons.lock_outline, color: _accentColor),
        filled: true,
        fillColor: _bgColor,
        errorText: _passwordError,
        errorStyle: TextStyle(color: _warningColor, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _warningColor, width:1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _warningColor, width:1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // 提交按钮（带按压缩放和加载状态）
  Widget _buildSubmitButton() {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.97),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: _isLoading ? null : _submit,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [_accentColor.withOpacity(0.5), _accentColor.withOpacity(0.5)]
                      : [_accentColor, _accentColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLoginMode ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoginMode ? '登录' : '注册',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 底部切换文本按钮
  Widget _buildToggleText() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() => _isLoginMode = !_isLoginMode);
        },
        style: TextButton.styleFrom(
          foregroundColor: _secondaryText,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        ),
        child: Text(
          _isLoginMode ? '还没有账号？点击注册' : '已有账号？点击登录',
          style: TextStyle(
            color: _secondaryText,
            decoration: TextDecoration.underline,
            decorationColor: _secondaryText.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
