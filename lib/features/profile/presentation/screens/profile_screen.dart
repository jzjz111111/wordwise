import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;

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
            // 头像
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 用户信息
            Center(
              child: Column(
                children: [
                  Text(
                    user?.email ?? '未登录',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '用户ID: ${user?.id?.substring(0, 8) ?? 'N/A'}...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 功能列表
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('邮箱'),
              subtitle: Text(user?.email ?? '未绑定'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('注册时间'),
              subtitle: Text(user?.createdAt?.toString().substring(0, 10) ?? '未知'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('云端同步'),
              subtitle: const Text('已同步'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),

            const SizedBox(height: 32),

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
}