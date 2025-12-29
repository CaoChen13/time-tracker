import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';
import '../data/category_provider.dart';

class CategoryEditDialog extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryEditDialog({super.key, this.category});

  @override
  ConsumerState<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends ConsumerState<CategoryEditDialog> {
  late TextEditingController _nameController;
  String _selectedColor = '#8B5CF6';
  String? _selectedIcon;

  static const _colors = [
    '#8B5CF6', '#EC4899', '#EF4444', '#F97316',
    '#EAB308', '#22C55E', '#14B8A6', '#06B6D4',
    '#3B82F6', '#6366F1', '#A855F7', '#D946EF',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? '#8B5CF6';
    _selectedIcon = widget.category?.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final selectedColorValue = Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));

    return AlertDialog(
      title: Text(isEditing ? '编辑分类' : '添加分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标预览 + 选择
            Center(
              child: GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: selectedColorValue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIconByName(_selectedIcon),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _pickIcon,
                child: const Text('选择图标'),
              ),
            ),
            const SizedBox(height: 16),
            // 名称输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '如：工作、学习、运动',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            // 颜色选择
            const Text(
              '选择颜色',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black87, width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
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

  Future<void> _pickIcon() async {
    final icon = await showIconPicker(context, selectedIcon: _selectedIcon);
    if (icon != null) {
      setState(() => _selectedIcon = icon);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分类名称')),
      );
      return;
    }

    final service = ref.read(categoryServiceProvider);

    if (widget.category != null) {
      service.updateCategory(widget.category!.copyWith(
        name: name,
        color: _selectedColor,
        icon: Value(_selectedIcon),
      ));
    } else {
      service.addCategory(name: name, color: _selectedColor, icon: _selectedIcon);
    }

    Navigator.pop(context);
  }
}
