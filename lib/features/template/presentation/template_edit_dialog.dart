import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../category/data/category_provider.dart';
import '../data/template_provider.dart';

class TemplateEditDialog extends ConsumerStatefulWidget {
  final EventTemplate? template;

  const TemplateEditDialog({super.key, this.template});

  @override
  ConsumerState<TemplateEditDialog> createState() => _TemplateEditDialogState();
}

class _TemplateEditDialogState extends ConsumerState<TemplateEditDialog> {
  late TextEditingController _nameController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _selectedCategoryId = widget.template?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(isEditing ? '编辑模板' : '添加模板'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '事件名称',
                hintText: '如：吃早餐、上班通勤',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            const Text(
              '选择分类',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Text(
                    '暂无分类，请先添加分类',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 无分类选项
                    _CategoryChip(
                      name: '无分类',
                      color: Colors.grey,
                      isSelected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    ...categories.map((c) {
                      final color = Color(
                          int.parse(c.color.replaceFirst('#', '0xFF')));
                      return _CategoryChip(
                        name: c.name,
                        color: color,
                        isSelected: _selectedCategoryId == c.id,
                        onTap: () => setState(() => _selectedCategoryId = c.id),
                      );
                    }),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('加载失败: $e'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事件名称')),
      );
      return;
    }

    final service = ref.read(templateServiceProvider);

    if (widget.template != null) {
      service.updateTemplate(widget.template!.copyWith(
        name: name,
        categoryId: Value(_selectedCategoryId),
      ));
    } else {
      service.addTemplate(
        name: name,
        categoryId: _selectedCategoryId,
      );
    }

    Navigator.pop(context);
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
