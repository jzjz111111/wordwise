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
  // ====================== 全局配色 ======================
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const Color _cardColor = Colors.white;
  static const Color _primaryText = Color(0xFF2D3142);
  static const Color _secondaryText = Color(0xFF9AA0B4);
  static const Color _accentColor = Color(0xFF8A9EDB);
  static const Color _accentBg = Color(0xFFF0F3FC);
  static const Color _successColor = Color(0xFF81C784);

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
          content: Text('$name 导入成功！共 $count 个单词'),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // 刷新页面
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: $e'),
          backgroundColor: const Color(0xFFFF8A75),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryText),
        title: const Text(
          '词库管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _primaryText,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _buildWordCard(
              icon: Icons.menu_book_rounded,
              name: '四级词汇',
              category: 'cet4',
              wordCount: 2607,
              isImported: _importedStatus['cet4'] ?? false,
              isCurrent: currentCategory == 'cet4',
              isImporting: _importingCategory == 'cet4',
            ),
            const SizedBox(height: 16),
            _buildWordCard(
              icon: Icons.library_books_rounded,
              name: '六级词汇',
              category: 'cet6',
              wordCount: 2345,
              isImported: _importedStatus['cet6'] ?? false,
              isCurrent: currentCategory == 'cet6',
              isImporting: _importingCategory == 'cet6',
            ),
            const SizedBox(height: 16),
            _buildWordCard(
              icon: Icons.auto_stories_rounded,
              name: '考研词汇',
              category: 'ky',
              wordCount: 4533,
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
    required IconData icon,
    required String name,
    required String category,
    required int wordCount,
    required bool isImported,
    required bool isCurrent,
    required bool isImporting,
  }) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setCardState(() => scale = 0.97),
          onTapUp: (_) => setCardState(() => scale = 1.0),
          onTapCancel: () => setCardState(() => scale = 1.0),
          onTap: () {
            // 已导入非当前，点击卡片直接切换
            if (isImported && !isCurrent && !isImporting) {
              ref.read(currentCategoryProvider.notifier).state = category;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已切换到 $name'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCurrent ? _accentBg.withOpacity(0.6) : _cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: isCurrent
                    ? Border.all(color: _accentColor.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  // 左侧图标
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCurrent ? _accentColor : _accentBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isCurrent ? Colors.white : _accentColor,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 中间文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$wordCount 个单词',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 右侧操作区
                  _buildActionWidget(
                    category: category,
                    name: name,
                    isImported: isImported,
                    isCurrent: isCurrent,
                    isImporting: isImporting,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionWidget({
    required String category,
    required String name,
    required bool isImported,
    required bool isCurrent,
    required bool isImporting,
  }) {
    // 导入中
    if (isImporting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '导入中',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
        ],
      );
    }

    // 使用中
    if (isCurrent && isImported) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '使用中',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // 已导入，未使用
    if (isImported) {
      return TextButton(
        onPressed: () {
          ref.read(currentCategoryProvider.notifier).state = category;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已切换到 $name'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        },
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('切换'),
      );
    }

    // 未导入
    return StatefulBuilder(
      builder: (context, setBtnState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setBtnState(() => scale = 0.93),
          onTapUp: (_) => setBtnState(() => scale = 1.0),
          onTapCancel: () => setBtnState(() => scale = 1.0),
          onTap: () => _importWordLibrary(category, name),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '导入',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../../core/database/word_importer.dart';
// import '../../../study/presentation/providers/word_category_provider.dart';
//
//
// class WordLibraryScreen extends ConsumerStatefulWidget {
//   const WordLibraryScreen({super.key});
//
//   @override
//   ConsumerState<WordLibraryScreen> createState() => _WordLibraryScreenState();
// }
//
// class _WordLibraryScreenState extends ConsumerState<WordLibraryScreen> {
//   // 词库导入状态
//   final Map<String, bool> _importedStatus = {
//     'cet4': false,
//     'cet6': false,
//     'ky': false,
//   };
//   bool _isLoading = true;
//   String? _importingCategory;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadImportedStatus();
//   }
//
//   /// 从 SharedPreferences 读取已导入状态
//   Future<void> _loadImportedStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _importedStatus['cet4'] = prefs.getBool('wordlib_cet4') ?? false;
//       _importedStatus['cet6'] = prefs.getBool('wordlib_cet6') ?? false;
//       _importedStatus['ky'] = prefs.getBool('wordlib_ky') ?? false;
//       _isLoading = false;
//     });
//   }
//
//   /// 保存导入状态到 SharedPreferences
//   Future<void> _saveImportedStatus(String category, bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('wordlib_$category', value);
//   }
//
//   /// 真实导入词库
//   Future<void> _importWordLibrary(String category, String name) async {
//     // 防止重复点击
//     if (_importingCategory != null) return;
//
//     setState(() {
//       _importingCategory = category;
//     });
//
//     try {
//       // 1. 确定文件路径
//       final pathMap = {
//         'cet4': 'assets/dicts/CET4.json',
//         'cet6': 'assets/dicts/CET6.json',
//         'ky': 'assets/dicts/KaoYan.json',
//       };
//       final assetPath = pathMap[category];
//
//       // 2. 执行导入
//       final count = await WordImporter.importFromAssets(
//         assetPath: assetPath!,
//         category: category,
//         clearExisting: true,
//       );
//
//       // 3. 更新状态
//       _importedStatus[category] = true;
//       await _saveImportedStatus(category, true);
//
//       // 4. 自动切换到当前词库
//       ref.read(currentCategoryProvider.notifier).state = category;
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ $name 导入成功！共 $count 个单词'),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       // 刷新页面
//       setState(() {});
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ 导入失败: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _importingCategory = null;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentCategory = ref.watch(currentCategoryProvider);
//
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('📚 词库管理'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildWordCard(
//               icon: '📘',
//               name: '四级词汇',
//               category: 'cet4',
//               wordCount: 2607,
//               isImported: _importedStatus['cet4'] ?? false,
//               isCurrent: currentCategory == 'cet4',
//               isImporting: _importingCategory == 'cet4',
//             ),
//             const SizedBox(height: 12),
//             _buildWordCard(
//               icon: '📗',
//               name: '六级词汇',
//               category: 'cet6',
//               wordCount: 2345,
//               isImported: _importedStatus['cet6'] ?? false,
//               isCurrent: currentCategory == 'cet6',
//               isImporting: _importingCategory == 'cet6',
//             ),
//             const SizedBox(height: 12),
//             _buildWordCard(
//               icon: '📕',
//               name: '考研词汇',
//               category: 'ky',
//               wordCount: 4533,
//               isImported: _importedStatus['ky'] ?? false,
//               isCurrent: currentCategory == 'ky',
//               isImporting: _importingCategory == 'ky',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWordCard({
//     required String icon,
//     required String name,
//     required String category,
//     required int wordCount,
//     required bool isImported,
//     required bool isCurrent,
//     required bool isImporting,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: isCurrent
//             ? const BorderSide(color: Colors.blue, width: 2)
//             : BorderSide.none,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Text(icon, style: const TextStyle(fontSize: 32)),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     '$wordCount 个单词',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (isCurrent && isImported)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   '使用中',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             const SizedBox(width: 8),
//             if (isImporting)
//               const SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               )
//             else if (isImported)
//               IconButton(
//                 icon: const Icon(Icons.check_circle, color: Colors.green),
//                 onPressed: () {
//                   // 切换到这个词库
//                   ref.read(currentCategoryProvider.notifier).state = category;
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('已切换到 $name')),
//                   );
//                   Navigator.pop(context);
//                 },
//               )
//             else
//               ElevatedButton(
//                 onPressed: () => _importWordLibrary(category, name),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('导入'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }