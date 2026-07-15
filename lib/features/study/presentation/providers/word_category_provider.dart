import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的词库类别
final currentCategoryProvider = StateProvider<String>((ref) {
  // 默认选中四级
  return 'cet4';
});

/// 所有可用词库列表
final categoriesProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'id': 'cet4', 'name': '四级词汇', 'icon': '📘'},
    {'id': 'cet6', 'name': '六级词汇', 'icon': '📗'},
    {'id': 'ky', 'name': '考研词汇', 'icon': '📕'},
  ];
});