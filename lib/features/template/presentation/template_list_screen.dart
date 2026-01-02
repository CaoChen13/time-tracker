import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';
import '../../category/data/category_provider.dart';
import '../../category/presentation/category_edit_sheet.dart';
import '../data/template_provider.dart';
import 'template_edit_sheet.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('事件模板'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('暂无模板', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('点击右下角添加常用事件模板', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
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
                  final category = template.categoryId != null ? categoryMap[template.categoryId] : null;
                  return _TemplateCard(template: template, category: category, isDark: isDark);
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showTemplateEditSheet(context);
  }
}

class _TemplateCard extends ConsumerStatefulWidget {
  final EventTemplate template;
  final Category? category;
  final bool isDark;

  const _TemplateCard({required this.template, this.category, required this.isDark});

  @override
  ConsumerState<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends ConsumerState<_TemplateCard> {
  double _dragExtent = 0;
  static const double _actionWidth = 80;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-_actionWidth, 0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _dragExtent = _dragExtent < -_actionWidth / 2 ? -_actionWidth : 0;
    });
  }

  void _resetPosition() {
    setState(() => _dragExtent = 0);
  }

  void _handleDelete() {
    showDeleteConfirmSheet(
      context: context,
      message: '确定要删除「${widget.template.name}」吗？',
      onConfirm: () => ref.read(templateServiceProvider).deleteTemplate(widget.template.id),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 68,
        child: Stack(
          children: [
            // 右侧删除按钮背景
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _actionWidth,
              child: GestureDetector(
                onTap: _handleDelete,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text('删除', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            // 前景卡片
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              left: _dragExtent,
              right: -_dragExtent,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                onTap: () {
                  if (_dragExtent != 0) {
                    _resetPosition();
                  } else {
                    showTemplateEditSheet(context, template: widget.template);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(child: IconDisplay(icon: widget.template.icon, size: 36)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.template.name, style: TextStyle(fontWeight: FontWeight.w500, color: widget.isDark ? Colors.white : null)),
                            if (widget.category != null)
                              Text(widget.category!.name, style: TextStyle(color: _parseColor(widget.category!.color), fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: widget.isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
