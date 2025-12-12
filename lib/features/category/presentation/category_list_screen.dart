import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_provider.dart';
import 'category_edit_dialog.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('暂无分类，点击右下角添加'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(category: category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryEditDialog(),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final dynamic category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(category.color);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: category.icon != null
            ? Icon(_parseIcon(category.icon), color: Colors.white)
            : Text(
                category.name.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
      ),
      title: Text(category.name),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            showDialog(
              context: context,
              builder: (context) => CategoryEditDialog(category: category),
            );
          } else if (value == 'delete') {
            _confirmDelete(context, ref);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(categoryServiceProvider).deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData _parseIcon(String? iconName) {
    // 简单的图标映射
    const iconMap = {
      'work': Icons.work,
      'study': Icons.school,
      'exercise': Icons.fitness_center,
      'sleep': Icons.bedtime,
      'eat': Icons.restaurant,
      'entertainment': Icons.sports_esports,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
