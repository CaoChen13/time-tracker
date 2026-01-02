import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';
import '../../category/data/category_provider.dart';
import '../../category/presentation/category_edit_sheet.dart';
import '../data/template_provider.dart';

class TemplateEditSheet extends ConsumerStatefulWidget {
  final EventTemplate? template;

  const TemplateEditSheet({super.key, this.template});

  @override
  ConsumerState<TemplateEditSheet> createState() => _TemplateEditSheetState();
}

class _TemplateEditSheetState extends ConsumerState<TemplateEditSheet> {
  late TextEditingController _nameController;
  int? _selectedCategoryId;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _selectedCategoryId = widget.template?.categoryId;
    _selectedIcon = widget.template?.icon;
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? '编辑模板' : '添加模板',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : null,
                  ),
                ),
                if (isEditing)
                  Pressable(
                    onTap: _confirmDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 内容区域
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标 + 事件名称
                  Row(
                    children: [
                      Pressable(
                        onTap: () async {
                          final icon = await showIconPicker(context, selectedIcon: _selectedIcon);
                          if (icon != null) {
                            setState(() => _selectedIcon = icon);
                          }
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: IconDisplay(icon: _selectedIcon, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(fontSize: 16, color: isDark ? Colors.white : null),
                          decoration: InputDecoration(
                            hintText: '事件名称',
                            hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 分类选择
                  Text(
                    '选择分类',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '暂无分类，请先添加分类',
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _CategoryChip(
                            name: '无分类',
                            color: Colors.grey,
                            isSelected: _selectedCategoryId == null,
                            isDark: isDark,
                            onTap: () => setState(() => _selectedCategoryId = null),
                          ),
                          ...categories.map((c) {
                            final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
                            return _CategoryChip(
                              name: c.name,
                              color: color,
                              isSelected: _selectedCategoryId == c.id,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedCategoryId = c.id),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('加载失败: $e'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // 底部按钮
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '取消',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: _save,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '保存',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        icon: Value(_selectedIcon),
      ));
    } else {
      service.addTemplate(
        name: name,
        categoryId: _selectedCategoryId,
        icon: _selectedIcon,
      );
    }

    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDeleteConfirmSheet(
      context: context,
      message: '确定删除「${widget.template?.name}」吗？',
      onConfirm: () {
        ref.read(templateServiceProvider).deleteTemplate(widget.template!.id);
        Navigator.pop(context); // 关闭确认
        Navigator.pop(context); // 关闭编辑
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isSelected ? 10 : 8,
              height: isSelected ? 10 : 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isSelected ? color : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(name),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示模板编辑 Sheet
void showTemplateEditSheet(BuildContext context, {EventTemplate? template}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TemplateEditSheet(template: template),
  );
}
