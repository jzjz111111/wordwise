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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ✅ 背景图控制器（用于视差效果）
  final ScrollController _scrollController = ScrollController();
  double _backgroundOffset = 0;

  // ✅ 签名控制器
  final TextEditingController _signatureController = TextEditingController();
  bool _isEditingSignature = false;

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

  void _loadSignature() {
    // TODO: 从 SharedPreferences 或 数据库加载签名
    _signatureController.text = '好好学习，天天向上';
  }

  Future<void> _saveSignature(String signature) async {
    // TODO: 保存到 SharedPreferences 或数据库
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
        body: Center(child: Text('未登录')),
      );
    }

    final profileAsync = ref.watch(profileProvider(user.id));
    final statsAsync = ref.watch(totalStudyStatsProvider);
    final currentCategory = ref.watch(currentCategoryProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ========== 头部（背景图 + 头像 + 昵称 + 签名） ==========
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ========== 内容区域 ==========
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // ✅ 统计卡片（ins风极简）
                _buildStatsRow(statsAsync),
                const SizedBox(height: 24),

                // ✅ 词库管理入口
                _buildMenuItem(
                  icon: Icons.library_books,
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
                const SizedBox(height: 8),

                // ✅ 修改密码入口
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: '修改密码',
                  subtitle: '修改您的登录密码',
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const SizedBox(height: 8),

                // ✅ 退出登录
                _buildMenuItem(
                  icon: Icons.logout,
                  title: '退出登录',
                  subtitle: null,
                  isDanger: true,
                  onTap: () => _showLogoutConfirm(context, ref),
                ),

                const SizedBox(height: 40),

                // ✅ 注册时间（底部版本号风格）
                Center(
                  child: Text(
                    '注册于 ${_formatDate(user.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
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

  // ========== 头部背景图 + 头像 + 昵称 + 签名 ==========
  Widget _buildHeaderBackground(
      BuildContext context,
      WidgetRef ref,
      AsyncValue<Profile?> profileAsync,
      User user,
      AsyncValue<TotalStudyStats> statsAsync,
      String currentCategory,
      ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ 背景图（可更换）
        _buildBackgroundImage(),

        // ✅ 渐变遮罩
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
        ),

        // ✅ 头像 + 昵称 + 签名（居中）
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // 头像（悬空效果）
              profileAsync.when(
                data: (profile) => _buildAvatarWithShadow(context, ref, profile, user),
                loading: () => _buildAvatarWithShadow(context, ref, null, user),
                error: (err, stack) => _buildAvatarWithShadow(context, ref, null, user),
              ),
              const SizedBox(height: 12),

              // 昵称（可点击修改）
              profileAsync.when(
                data: (profile) => _buildEditableName(profile?.username, user),
                loading: () => const Text(
                  '加载中...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                error: (err, stack) => _buildEditableName(null, user),
              ),
              const SizedBox(height: 6),

              // 签名（可点击修改）
              _buildEditableSignature(),
              const SizedBox(height: 8),

              // 连续学习 + 当前词库
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  statsAsync.when(
                    data: (stats) => _buildHeaderTag(
                      icon: '🔥',
                      label: '连续 ${stats.consecutiveDays} 天',
                    ),
                    loading: () => _buildHeaderTag(icon: '🔥', label: '--'),
                    error: (err, stack) => _buildHeaderTag(icon: '🔥', label: '--'),
                  ),
                  const SizedBox(width: 16),
                  _buildHeaderTag(
                    icon: '📚',
                    label: _getCategoryName(currentCategory),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== 背景图 ==========
  Widget _buildBackgroundImage() {
    // TODO: 从 SharedPreferences 读取用户选择的背景图
    // 目前使用默认渐变色背景
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
            Colors.pink.shade300,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 装饰元素（ins风）
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 头像（带阴影悬空效果） ==========
  Widget _buildAvatarWithShadow(
      BuildContext context,
      WidgetRef ref,
      Profile? profile,
      User user,
      ) {
    return GestureDetector(
      onTap: () => _pickAndUploadAvatar(context, ref, user.id),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white,
          backgroundImage: profile?.avatarUrl != null
              ? NetworkImage(profile!.avatarUrl!)
              : null,
          child: profile?.avatarUrl == null
              ? const Icon(
            Icons.person,
            size: 50,
            color: Colors.blue,
          )
              : null,
        ),
      ),
    );
  }

  // ========== 昵称（可点击修改） ==========
  Widget _buildEditableName(String? username, User user) {
    final displayName = username ?? user.email?.split('@').first ?? '用户';
    return GestureDetector(
      onTap: () => _showEditUsernameDialog(context, ref, user.id),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: Colors.white.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  // ========== 签名（可点击修改） ==========
  Widget _buildEditableSignature() {
    return GestureDetector(
      onTap: () => _showEditSignatureDialog(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _signatureController.text.isEmpty ? '点击添加签名' : _signatureController.text,
            style: TextStyle(
              fontSize: 14,
              color: _signatureController.text.isEmpty
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.edit_outlined,
            size: 12,
            color: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  // ========== 头部标签 ==========
  Widget _buildHeaderTag({
    required String icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========== 统计行（ins风极简） ==========
  Widget _buildStatsRow(AsyncValue<TotalStudyStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          _buildStatItem('📚', '${stats.totalWords}', '已学'),
          const SizedBox(width: 8),
          _buildStatItem('✅', '${stats.totalWords ~/ 2}', '已掌握'),
          const SizedBox(width: 8),
          _buildStatItem('🔥', '${stats.consecutiveDays}', '连续'),
        ],
      ),
      loading: () => Row(
        children: [
          _buildStatItem('📚', '--', '已学'),
          const SizedBox(width: 8),
          _buildStatItem('✅', '--', '已掌握'),
          const SizedBox(width: 8),
          _buildStatItem('🔥', '--', '连续'),
        ],
      ),
      error: (err, stack) => Row(
        children: [
          _buildStatItem('📚', '?', '已学'),
          const SizedBox(width: 8),
          _buildStatItem('✅', '?', '已掌握'),
          const SizedBox(width: 8),
          _buildStatItem('🔥', '?', '连续'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 菜单项（ins风格，带动态效果） ==========
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : Colors.grey[700],
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  // ========== 修改密码弹窗 ==========
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('当前邮箱：', style: TextStyle(fontSize: 14)),
            Text(
              ref.read(authProvider).currentUser?.email ?? '未绑定',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: '当前密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final old = oldPasswordController.text.trim();
              final newPwd = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (old.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息')),
                );
                return;
              }
              if (newPwd != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次密码不一致')),
                );
                return;
              }
              if (newPwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码至少6位')),
                );
                return;
              }

              // TODO: 调用 Supabase 修改密码 API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('密码修改功能开发中...')),
              );
              Navigator.pop(context);
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  // ========== 退出登录 ==========
  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider).signOut();
              ref.invalidate(dailyStudyStatsProvider);
              ref.invalidate(masteryDistributionProvider);
              ref.invalidate(totalStudyStatsProvider);
              if (!context.mounted) return;
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  // ========== 修改签名弹窗 ==========
  void _showEditSignatureDialog(BuildContext context) {
    final controller = TextEditingController(text: _signatureController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改签名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入你的签名',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
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

  // ========== 工具方法 ==========
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

  // ========== 头像上传 ==========
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
      ref.refresh(profileProvider(userId));

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

  // ========== 修改昵称弹窗 ==========
  void _showEditUsernameDialog(
      BuildContext context,
      WidgetRef ref,
      String userId,
      ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
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
              ref.refresh(profileProvider(userId));

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
}
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:wordwise/features/profile/presentation/screens/word_library_screen.dart';
// import '../../../auth/presentation/providers/auth_provider.dart';
// import '../../../study/presentation/providers/study_stats_provider.dart';
// import '../../../study/presentation/providers/word_category_provider.dart';
// import '../../domain/entities/profile.dart';
// import '../providers/profile_provider.dart';
//
// class ProfileScreen extends ConsumerWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final auth = ref.watch(authProvider);
//     final user = auth.currentUser;
//
//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text('未登录')),
//       );
//     }
//
//     final profileAsync = ref.watch(profileProvider(user.id));
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('👤 个人中心'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 头像 + 昵称
//             profileAsync.when(
//               data: (profile) => _buildHeader(context, ref, profile, user),
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (err, stack) => _buildHeader(context, ref, null, user),
//             ),
//
//             const SizedBox(height: 32),
//             const Divider(),
//             const SizedBox(height: 16),
//
//             // 功能列表
//             ListTile(
//               leading: const Icon(Icons.email),
//               title: const Text('邮箱'),
//               subtitle: Text(user.email ?? '未绑定'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.calendar_today),
//               title: const Text('注册时间'),
//               subtitle: Text(
//                 user.createdAt != null && user.createdAt!.length >= 10
//                     ? user.createdAt!.substring(0, 10)
//                     : '未知',
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.cloud_sync),
//               title: const Text('云端同步'),
//               subtitle: const Text('已同步'),
//               trailing: const Icon(Icons.check_circle, color: Colors.green),
//             ),
//             // 在“云端同步”和“修改昵称”之间添加
//             ListTile(
//               leading: const Icon(Icons.library_books),
//               title: const Text('词库管理'),
//               subtitle: Text('当前：${_getCategoryName(ref.watch(currentCategoryProvider))}'),
//               trailing: const Icon(Icons.chevron_right),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const WordLibraryScreen(),
//                   ),
//                 );
//               },
//             ),
//
//             const SizedBox(height: 32),
//
//             // 编辑昵称按钮
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: () {
//                   _showEditUsernameDialog(context, ref, user.id);
//                 },
//                 icon: const Icon(Icons.edit),
//                 label: const Text('修改昵称'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             // 退出登录按钮
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () async {
//                   final confirm = await showDialog<bool>(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: const Text('确认退出'),
//                       content: const Text('确定要退出登录吗？'),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context, false),
//                           child: const Text('取消'),
//                         ),
//                         TextButton(
//                           onPressed: () => Navigator.pop(context, true),
//                           child: const Text('退出'),
//                         ),
//                       ],
//                     ),
//                   );
//
//                   if (confirm == true) {
//                     await ref.read(authProvider).signOut();
//
//                     ref.invalidate(dailyStudyStatsProvider);
//                     ref.invalidate(masteryDistributionProvider);
//                     ref.invalidate(totalStudyStatsProvider);
//
//                     if (!context.mounted) return;
//                     context.go('/login');
//                   }
//                 },
//                 icon: const Icon(Icons.logout),
//                 label: const Text('退出登录'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(
//       BuildContext context,
//       WidgetRef ref,
//       Profile? profile,
//       User user,
//       ) {
//     return Center(
//       child: Column(
//         children: [
//           // ✅ 可点击的头像
//           GestureDetector(
//             onTap: () => _pickAndUploadAvatar(context, ref, user.id),
//             child: Stack(
//               children: [
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.blue,
//                   backgroundImage: profile?.avatarUrl != null
//                       ? NetworkImage(profile!.avatarUrl!)
//                       : null,
//                   child: profile?.avatarUrl == null
//                       ? const Icon(Icons.person, size: 50, color: Colors.white)
//                       : null,
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: const BoxDecoration(
//                       color: Colors.blue,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.camera_alt,
//                       size: 16,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             profile?.username ?? user.email?.split('@').first ?? '用户',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '用户ID: ${user.id.substring(0, 8)}...',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '👆 点击头像更换',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickAndUploadAvatar(
//       BuildContext context,
//       WidgetRef ref,
//       String userId,
//       ) async {
//     try {
//       // 选择图片
//       final picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 400,
//         maxHeight: 400,
//         imageQuality: 80,
//       );
//
//       if (image == null) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('⏳ 上传头像中...')),
//       );
//
//       // 上传头像
//       final repository = ref.read(profileRepositoryProvider);
//       final avatarUrl = await repository.uploadAvatar(userId, image.path);
//
//       // 更新 profiles 表
//       await repository.updateAvatar(userId, avatarUrl);
//
//       // ✅ 强制刷新
//       ref.invalidate(profileProvider(userId));
//       ref.refresh(profileProvider(userId));
//
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('✅ 头像已更新')),
//       );
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❌ 上传失败: $e')),
//       );
//     }
//   }
//
//   void _showEditUsernameDialog(
//       BuildContext context,
//       WidgetRef ref,
//       String userId,
//       ) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('修改昵称'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             hintText: '请输入新昵称',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('取消'),
//           ),
//           TextButton(
//             onPressed: () async {
//               final newUsername = controller.text.trim();
//               if (newUsername.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('昵称不能为空')),
//                 );
//                 return;
//               }
//               // 更新昵称
//               final repository = ref.read(profileRepositoryProvider);
//               await repository.updateUsername(userId, newUsername);
//
//               // ✅ 强制刷新
//               ref.invalidate(profileProvider(userId));
//               ref.refresh(profileProvider(userId));
//
//               Navigator.pop(context);
//               if (!context.mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('✅ 昵称已更新')),
//               );
//             },
//             child: const Text('保存'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getCategoryName(String categoryId) {
//     switch (categoryId) {
//       case 'cet4':
//         return '四级词汇';
//       case 'cet6':
//         return '六级词汇';
//       case 'ky':
//         return '考研词汇';
//       default:
//         return '未选择';
//     }
//   }
// }