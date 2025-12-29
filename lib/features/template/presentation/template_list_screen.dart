import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../category/data/category_provider.dart';
import '../data/template_provider.dart';
import 'template_edit_dialog.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      appBar: AppBar(
        title: const Text('事件模板'),
        backgroundColor: const Color(0xFFFAFAFF),
        elevation: 0,
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无模板',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角添加常用事件模板',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return categoriesAsync.when(
            data: (categories) {
              final categoryMap = {for (var c in categories) c.id: c};
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final category = template.categoryId != null
                      ? categoryMap[template.categoryId]
                      : null;
                  return _TemplateCard(
                    template: template,
                    category: category,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TemplateEditDialog(),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final EventTemplate template;
  final Category? category;

  const _TemplateCard({required this.template, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = category != null
        ? Color(int.parse(category!.color.replaceFirst('#', '0xFF')))
        : const Color(0xFF8B5CF6);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: categoryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            category?.icon != null
                ? getIconByName(category!.icon)
                : Icons.bookmark_outline,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: category != null
            ? Text(
                category!.name,
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (context) => TemplateEditDialog(template: template),
              );
            } else if (value == 'delete') {
              _confirmDelete(context, ref);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板"${template.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(templateServiceProvider).deleteTemplate(template.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
