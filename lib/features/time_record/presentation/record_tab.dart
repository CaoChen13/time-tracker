import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../template/data/template_provider.dart';
import '../../template/presentation/template_edit_sheet.dart';
import '../../category/data/category_provider.dart';
import '../../category/presentation/category_edit_sheet.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';
import 'timer_card.dart';
import 'template_list.dart';

class RecordTab extends ConsumerWidget {
  const RecordTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Task 标题栏
            const _TaskHeader(),
            // 计时器卡片（计划外事件）
            const TimerCard(),
            const SizedBox(height: 16),
            // 快捷启动标题
            const _TodayHeader(),
            // 快捷启动列表（放中间）
            const Expanded(child: TemplateList()),
            // 事件库（放底部）
            const _QuickTemplates(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// TimePad 风格的 Task 标题栏
class _TaskHeader extends StatelessWidget {
  const _TaskHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Task',
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: 更多菜单
            },
            child: Icon(
              Icons.more_horiz,
              size: 24,
              color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Today 标题 -> 改为"快捷启动"
class _TodayHeader extends ConsumerWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '快捷启动',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              // 添加新模板
              showTemplateEditSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '添加',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// 事件库 - 底部 Bento Grid 样式
class _QuickTemplates extends ConsumerStatefulWidget {
  const _QuickTemplates();

  @override
  ConsumerState<_QuickTemplates> createState() => _QuickTemplatesState();
}

class _QuickTemplatesState extends ConsumerState<_QuickTemplates> {
  bool _isExpanded = false;
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Pressable(
              onTap: () => showTemplateEditSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      '添加事件到事件库',
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return categoriesAsync.when(
          data: (categories) {
            final categoryMap = {for (var c in categories) c.id: c};

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Pressable(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Row(
                          children: [
                            Text(
                              '事件库',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Pressable(
                            onTap: () => setState(() => _isEditMode = !_isEditMode),
                            child: Text(
                              _isEditMode ? '完成' : '编辑',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _isEditMode ? AppColors.error : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Pressable(
                            onTap: () => showTemplateEditSheet(context),
                            child: Text(
                              '新建',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bento Grid 内容
                  if (_isExpanded)
                    _buildExpandedGrid(templates, categoryMap)
                  else
                    _buildCollapsedRow(templates, categoryMap),
                ],
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildCollapsedRow(
    List<EventTemplate> templates,
    Map<int, Category> categoryMap,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: templates.map((t) {
          final category = t.categoryId != null ? categoryMap[t.categoryId] : null;
          return _TemplateTile(
            template: t,
            category: category,
            isEditMode: _isEditMode,
            onTap: () => _addToQuickAccess(t),
            onLongPress: () => _confirmDelete(t),
            onDelete: () => _deleteTemplate(t),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedGrid(
    List<EventTemplate> templates,
    Map<int, Category> categoryMap,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: templates.map((t) {
        final category = t.categoryId != null ? categoryMap[t.categoryId] : null;
        return _TemplateTile(
          template: t,
          category: category,
          isEditMode: _isEditMode,
          onTap: () => _addToQuickAccess(t),
          onLongPress: () => _confirmDelete(t),
          onDelete: () => _deleteTemplate(t),
        );
      }).toList(),
    );
  }

  void _addToQuickAccess(EventTemplate template) {
    if (!template.isQuickAccess) {
      ref.read(templateServiceProvider).setQuickAccess(template.id, true);
    }
  }

  void _deleteTemplate(EventTemplate template) {
    ref.read(templateServiceProvider).deleteTemplate(template.id);
  }

  void _confirmDelete(EventTemplate template) {
    showDeleteConfirmSheet(
      context: context,
      message: '确定要删除「${template.name}」吗？',
      onConfirm: () {
        ref.read(templateServiceProvider).deleteTemplate(template.id);
      },
    );
  }
}

// Bento 方块卡片（小尺寸 64x52）
class _TemplateTile extends StatelessWidget {
  final EventTemplate template;
  final Category? category;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _TemplateTile({
    required this.template,
    this.category,
    required this.isEditMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? Color(int.parse(category!.color.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Pressable(
          onTap: isEditMode ? null : onTap,
          child: GestureDetector(
            onLongPress: isEditMode ? null : onLongPress,
            child: Container(
              width: 64,
              height: 52,
              margin: const EdgeInsets.only(right: 2, top: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconDisplay(icon: template.icon, size: 20),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 编辑模式删除按钮
        if (isEditMode)
          Positioned(
            top: 0,
            right: -2,
            child: Pressable(
              onTap: onDelete,
              scaleFactor: 0.9,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
