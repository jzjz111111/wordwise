import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../study/domain/entities/study_stats.dart';
import '../../../study/presentation/providers/study_stats_provider.dart';
import '../../../study/presentation/providers/word_category_provider.dart';
import '../../../study/presentation/screens/settings_screen.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';
import 'word_library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  double _backgroundOffset = 0;

  final TextEditingController _signatureController = TextEditingController();
  bool _isEditingSignature = false;

  static const String _signatureKey = 'user_signature';

  // ====================== 全局配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _dangerColor = Color(0xFFFF8A75);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSignature();
  }

  void _onScroll() {
    setState(() {
      _backgroundOffset = _scrollController.position.pixels;
    });
  }

  void _loadSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 只读取真实签名，没有就是空字符串
      final signature = prefs.getString(_signatureKey) ?? '';
      setState(() {
        _signatureController.text = signature;
      });
    } catch (e) {
      _signatureController.text = '';
    }
  }

  Future<void> _saveSignature(String signature) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_signatureKey, signature);
    } catch (e) {
      print('保存签名失败: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text(
            '未登录',
            style: TextStyle(color: _secondaryText, fontSize: 14),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(profileProvider(user.id));
    final statsAsync = ref.watch(totalStudyStatsProvider);
    final currentCategory = ref.watch(currentCategoryProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHeaderBackground(
                context,
                ref,
                profileAsync,
                user,
                statsAsync,
                currentCategory,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildStatsRow(statsAsync),
                const SizedBox(height: 28),
                _buildMenuItem(
                  icon: Icons.library_books_rounded,
                  title: '词库管理',
                  subtitle: _getCategoryName(currentCategory),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WordLibraryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: '修改密码',
                  subtitle: '修改您的登录密码',
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: '退出登录',
                  subtitle: null,
                  isDanger: true,
                  onTap: () => _showLogoutConfirm(context, ref),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    '注册于 ${_formatDate(user.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(
      BuildContext context,
      WidgetRef ref,
      AsyncValue<Profile?> profileAsync,
      User user,
      AsyncValue<TotalStudyStats> statsAsync,
      String currentCategory,
      ) {
    String? backgroundUrl;
    profileAsync.when(
      data: (profile) => backgroundUrl = profile?.backgroundUrl,
      loading: () {},
      error: (err, stack) => {},
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundImage(context, ref, backgroundUrl, user.id),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.55),
              ],
              stops: const [0.2, 0.55, 1.0],
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _changeBackground(context, ref, user.id),
            child: const SizedBox.expand(),
          ),
        ),

        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              profileAsync.when(
                data: (profile) => _buildAvatarWithShadow(context, ref, profile, user),
                loading: () => _buildAvatarWithShadow(context, ref, null, user),
                error: (err, stack) => _buildAvatarWithShadow(context, ref, null, user),
              ),
              const SizedBox(height: 12),
              profileAsync.when(
                data: (profile) => _buildEditableName(profile?.username, user),
                loading: () => const Text(
                  '加载中...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                error: (err, stack) => _buildEditableName(null, user),
              ),
              const SizedBox(height: 6),
              _buildEditableSignature(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage(
      BuildContext context,
      WidgetRef ref,
      String? backgroundUrl,
      String userId,
      ) {
    Widget backgroundChild;

    if (backgroundUrl != null && backgroundUrl.isNotEmpty) {
      backgroundChild = Image.network(
        backgroundUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildDefaultBackground();
        },
        errorBuilder: (context, error, stackTrace) => _buildDefaultBackground(),
      );
    } else {
      backgroundChild = _buildDefaultBackground();
    }

    return GestureDetector(
      onTap: () {
        print('📍 点击背景');
        _changeBackground(context, ref, userId);
      },
      behavior: HitTestBehavior.opaque,
      child: backgroundChild,
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA8B8E8),
            Color(0xFF8A9EDB),
            Color(0xFF6F86C8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithShadow(
      BuildContext context,
      WidgetRef ref,
      Profile? profile,
      User user,
      ) {
    return GestureDetector(
      onTap: () => _pickAndUploadAvatar(context, ref, user.id),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: _cardColor,
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? const Icon(
              Icons.person_rounded,
              size: 48,
              color: _accentColor,
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableName(String? username, User user) {
    final displayName = username ?? user.email?.split('@').first ?? '用户';
    return GestureDetector(
      onTap: () => _showEditUsernameDialog(context, ref, user.id),
      behavior: HitTestBehavior.opaque,
      child: Text(
        displayName,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildEditableSignature() {
    final isEmpty = _signatureController.text.isEmpty;
    return GestureDetector(
      onTap: () => _showEditSignatureDialog(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEmpty ? '写下一句专属签名吧' : _signatureController.text,
            style: TextStyle(
              fontSize: 13,
              color: isEmpty
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.85),
              fontStyle: FontStyle.italic,
              height: 1.4,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.edit_outlined,
            size: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }




  Widget _buildStatsRow(AsyncValue<TotalStudyStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          _buildStatItem(Icons.menu_book_rounded, '${stats.totalWords}', '已学'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.check_circle_outline_rounded, '${stats.totalMastered}', '已掌握'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.local_fire_department_rounded, '${stats.consecutiveDays}', '连续'),
        ],
      ),
      loading: () => Row(
        children: [
          _buildStatItem(Icons.menu_book_rounded, '--', '已学'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.check_circle_outline_rounded, '--', '已掌握'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.local_fire_department_rounded, '--', '连续'),
        ],
      ),
      error: (err, stack) => Row(
        children: [
          _buildStatItem(Icons.menu_book_rounded, '?', '已学'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.check_circle_outline_rounded, '?', '已掌握'),
          const SizedBox(width: 12),
          _buildStatItem(Icons.local_fire_department_rounded, '?', '连续'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _accentColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _primaryText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.96),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDanger
                          ? _dangerColor.withOpacity(0.12)
                          : _accentBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isDanger ? _dangerColor : _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDanger ? _dangerColor : _primaryText,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '修改密码',
              style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('当前邮箱：', style: TextStyle(fontSize: 14, color: _primaryText)),
                      Expanded(
                        child: Text(
                          ref.read(authProvider).currentUser?.email ?? '未绑定',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: '当前密码',
                      labelStyle: const TextStyle(color: _secondaryText),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: _accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      labelStyle: const TextStyle(color: _secondaryText),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: _accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      labelStyle: const TextStyle(color: _secondaryText),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: _accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentBg),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('取消', style: TextStyle(color: _secondaryText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                  final oldPwd = oldPasswordController.text.trim();
                  final newPwd = newPasswordController.text.trim();
                  final confirmPwd = confirmPasswordController.text.trim();

                  if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写完整信息')),
                    );
                    return;
                  }
                  if (newPwd.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码至少6位')),
                    );
                    return;
                  }
                  if (newPwd != confirmPwd) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('两次密码不一致')),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    final supabase = Supabase.instance.client;
                    await supabase.auth.updateUser(
                      UserAttributes(password: newPwd),
                    );
                    await supabase.auth.refreshSession();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 密码修改成功'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 修改失败: $e'),
                        backgroundColor: _dangerColor,
                      ),
                    );
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('确认修改'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '确认退出',
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '确定要退出登录吗？',
          style: TextStyle(color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ref.read(authProvider).signOut();
              ref.invalidate(dailyStudyStatsProvider);
              ref.invalidate(masteryDistributionProvider);
              ref.invalidate(totalStudyStatsProvider);
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showEditSignatureDialog(BuildContext context) {
    final controller = TextEditingController(text: _signatureController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '修改签名',
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: '输入你的签名',
            hintStyle: const TextStyle(color: _secondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentBg),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentBg),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _signatureController.text = controller.text.trim();
                _saveSignature(_signatureController.text);
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'cet4':
        return '四级词汇';
      case 'cet6':
        return '六级词汇';
      case 'ky':
        return '考研词汇';
      default:
        return '未选择';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}年${date.month}月${date.day}日';
    } catch (e) {
      return dateStr.substring(0, 10);
    }
  }

  Future<void> _pickAndUploadAvatar(
      BuildContext context,
      WidgetRef ref,
      String userId,
      ) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ 上传头像中...')),
      );

      final repository = ref.read(profileRepositoryProvider);
      final avatarUrl = await repository.uploadAvatar(userId, image.path);
      await repository.updateAvatar(userId, avatarUrl);

      ref.invalidate(profileProvider(userId));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 头像已更新')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 上传失败: $e')),
      );
    }
  }

  void _showEditUsernameDialog(
      BuildContext context,
      WidgetRef ref,
      String userId,
      ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '修改昵称',
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '请输入新昵称',
            hintStyle: const TextStyle(color: _secondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentBg),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentBg),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('昵称不能为空')),
                );
                return;
              }
              final repository = ref.read(profileRepositoryProvider);
              await repository.updateUsername(userId, newUsername);

              ref.invalidate(profileProvider(userId));

              Navigator.pop(context);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 昵称已更新')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeBackground(BuildContext context, WidgetRef ref, String userId) async {
    print('📍 点击背景，进入 _changeBackground');

    final picker = ImagePicker();
    print('📍 准备打开相册...');

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );

    print('📍 相册返回结果: ${image != null ? "选择了图片" : "取消选择"}');

    if (image == null) return;

    try {
      print('📍 开始上传图片到 Supabase...');

      final repository = ref.read(profileRepositoryProvider);
      final backgroundUrl = await repository.uploadBackground(userId, image.path);
      print('📍 上传成功，URL: $backgroundUrl');

      await repository.updateBackground(userId, backgroundUrl);
      print('📍 更新 profiles 表成功');

      ref.invalidate(profileProvider(userId));
      print('📍 刷新 Provider 成功');


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 背景已更新')),
      );
    } catch (e) {
      print('📍 ❌ 出错: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 上传失败: $e')),
      );
    }
  }
}
