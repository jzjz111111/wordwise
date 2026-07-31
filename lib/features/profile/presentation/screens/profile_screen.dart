import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('未登录')),
      );
    }

    final profileAsync = ref.watch(profileProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 个人中心'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像 + 昵称
            profileAsync.when(
              data: (profile) => _buildHeader(context, ref, profile, user),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildHeader(context, ref, null, user),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 功能列表
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('邮箱'),
              subtitle: Text(user.email ?? '未绑定'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('注册时间'),
              subtitle: Text(
                user.createdAt != null && user.createdAt!.length >= 10
                    ? user.createdAt!.substring(0, 10)
                    : '未知',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('云端同步'),
              subtitle: const Text('已同步'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),

            const SizedBox(height: 32),

            // 编辑昵称按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showEditUsernameDialog(context, ref, user.id);
                },
                icon: const Icon(Icons.edit),
                label: const Text('修改昵称'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 退出登录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认退出'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('退出'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authProvider).signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      WidgetRef ref,
      Profile? profile,
      User user,
      ) {
    return Center(
      child: Column(
        children: [
          // ✅ 可点击的头像
          GestureDetector(
            onTap: () => _pickAndUploadAvatar(context, ref, user.id),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?.username ?? user.email?.split('@').first ?? '用户',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '用户ID: ${user.id.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '👆 点击头像更换',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(
      BuildContext context,
      WidgetRef ref,
      String userId,
      ) async {
    try {
      // 选择图片
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

      // 上传头像
      final repository = ref.read(profileRepositoryProvider);
      final avatarUrl = await repository.uploadAvatar(userId, image.path);

      // 更新 profiles 表
      await repository.updateAvatar(userId, avatarUrl);

      // ✅ 强制刷新
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
          TextButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('昵称不能为空')),
                );
                return;
              }
              // 更新昵称
              final repository = ref.read(profileRepositoryProvider);
              await repository.updateUsername(userId, newUsername);

              // ✅ 强制刷新
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