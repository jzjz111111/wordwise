import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/word_importer.dart';
import '../../../study/presentation/providers/word_category_provider.dart';


class WordLibraryScreen extends ConsumerStatefulWidget {
  const WordLibraryScreen({super.key});

  @override
  ConsumerState<WordLibraryScreen> createState() => _WordLibraryScreenState();
}

class _WordLibraryScreenState extends ConsumerState<WordLibraryScreen> {
  // 词库导入状态
  final Map<String, bool> _importedStatus = {
    'cet4': false,
    'cet6': false,
    'ky': false,
  };
  bool _isLoading = true;
  String? _importingCategory;

  @override
  void initState() {
    super.initState();
    _loadImportedStatus();
  }

  /// 从 SharedPreferences 读取已导入状态
  Future<void> _loadImportedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _importedStatus['cet4'] = prefs.getBool('wordlib_cet4') ?? false;
      _importedStatus['cet6'] = prefs.getBool('wordlib_cet6') ?? false;
      _importedStatus['ky'] = prefs.getBool('wordlib_ky') ?? false;
      _isLoading = false;
    });
  }

  /// 保存导入状态到 SharedPreferences
  Future<void> _saveImportedStatus(String category, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wordlib_$category', value);
  }

  /// 真实导入词库
  Future<void> _importWordLibrary(String category, String name) async {
    // 防止重复点击
    if (_importingCategory != null) return;

    setState(() {
      _importingCategory = category;
    });

    try {
      // 1. 确定文件路径
      final pathMap = {
        'cet4': 'assets/dicts/CET4.json',
        'cet6': 'assets/dicts/CET6.json',
        'ky': 'assets/dicts/KaoYan.json',
      };
      final assetPath = pathMap[category];

      // 2. 执行导入
      final count = await WordImporter.importFromAssets(
        assetPath: assetPath!,
        category: category,
        clearExisting: true,
      );

      // 3. 更新状态
      _importedStatus[category] = true;
      await _saveImportedStatus(category, true);

      // 4. 自动切换到当前词库
      ref.read(currentCategoryProvider.notifier).state = category;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $name 导入成功！共 $count 个单词'),
          backgroundColor: Colors.green,
        ),
      );

      // 刷新页面
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 导入失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importingCategory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = ref.watch(currentCategoryProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 词库管理'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWordCard(
              icon: '📘',
              name: '四级词汇',
              category: 'cet4',
              wordCount: 7508,
              isImported: _importedStatus['cet4'] ?? false,
              isCurrent: currentCategory == 'cet4',
              isImporting: _importingCategory == 'cet4',
            ),
            const SizedBox(height: 12),
            _buildWordCard(
              icon: '📗',
              name: '六级词汇',
              category: 'cet6',
              wordCount: 5651,
              isImported: _importedStatus['cet6'] ?? false,
              isCurrent: currentCategory == 'cet6',
              isImporting: _importingCategory == 'cet6',
            ),
            const SizedBox(height: 12),
            _buildWordCard(
              icon: '📕',
              name: '考研词汇',
              category: 'ky',
              wordCount: 9602,
              isImported: _importedStatus['ky'] ?? false,
              isCurrent: currentCategory == 'ky',
              isImporting: _importingCategory == 'ky',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard({
    required String icon,
    required String name,
    required String category,
    required int wordCount,
    required bool isImported,
    required bool isCurrent,
    required bool isImporting,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$wordCount 个单词',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent && isImported)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '使用中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (isImporting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isImported)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  // 切换到这个词库
                  ref.read(currentCategoryProvider.notifier).state = category;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已切换到 $name')),
                  );
                  Navigator.pop(context);
                },
              )
            else
              ElevatedButton(
                onPressed: () => _importWordLibrary(category, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('导入'),
              ),
          ],
        ),
      ),
    );
  }
}