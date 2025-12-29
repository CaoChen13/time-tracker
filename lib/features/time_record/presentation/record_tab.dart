import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../template/data/template_provider.dart';
import '../../template/presentation/template_edit_dialog.dart';
import '../../category/data/category_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';
import 'timer_card.dart';
import 'template_list.dart';

class RecordTab extends ConsumerWidget {
  const RecordTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Task 标题栏
            const _TaskHeader(),
            // 计时器卡片
            const TimerCard(),
            const SizedBox(height: 12),
            // 常用模板
            const _QuickTemplates(),
            const SizedBox(height: 8),
            // Today 标题
            const _TodayHeader(),
            // 模板列表（快捷启动）
            const Expanded(child: TemplateList()),
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
              color: const Color(0xFF070417),
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: 更多菜单
            },
            child: const Icon(
              Icons.more_horiz,
              size: 24,
              color: Color(0xFF828282),
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
              color: const Color(0xFF070417),
            ),
          ),
          GestureDetector(
            onTap: () {
              // 添加新模板
              showDialog(
                context: context,
                builder: (context) => const TemplateEditDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 4),
                  Text(
                    '添加',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B5CF6),
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



// 事件库横条 - 可展开显示全部事件
class _QuickTemplates extends ConsumerStatefulWidget {
  const _QuickTemplates();

  @override
  ConsumerState<_QuickTemplates> createState() => _QuickTemplatesState();
}

class _QuickTemplatesState extends ConsumerState<_QuickTemplates> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const TemplateEditDialog(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      '添加事件到事件库',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Row(
                          children: [
                            Text(
                              '事件库',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const TemplateEditDialog(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Color(0xFF8B5CF6)),
                              SizedBox(width: 2),
                              Text(
                                '新建',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 事件列表
                  if (_isExpanded)
                    _buildExpandedList(templates, categoryMap)
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
          return _TemplateChip(
            template: t,
            category: category,
            onTap: () => _addToQuickAccess(t),
            onLongPress: () => _confirmDelete(t),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedList(
    List<EventTemplate> templates,
    Map<int, Category> categoryMap,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.map((t) {
        final category = t.categoryId != null ? categoryMap[t.categoryId] : null;
        return _TemplateChip(
          template: t,
          category: category,
          onTap: () => _addToQuickAccess(t),
          onLongPress: () => _confirmDelete(t),
        );
      }).toList(),
    );
  }

  // 只添加到快捷启动（如果已经在了就不操作）
  void _addToQuickAccess(EventTemplate template) {
    if (!template.isQuickAccess) {
      ref.read(templateServiceProvider).setQuickAccess(template.id, true);
    }
  }

  void _confirmDelete(EventTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${template.name}"吗？'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final EventTemplate template;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TemplateChip({
    required this.template,
    this.category,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? Color(int.parse(category!.color.replaceFirst('#', '0xFF')))
        : const Color(0xFF8B5CF6);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category?.icon != null
                  ? getIconByName(category!.icon)
                  : Icons.bookmark_outline,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
