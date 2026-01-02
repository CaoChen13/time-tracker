import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../data/category_provider.dart';

/// 快捷分类页面 - 管理 TimerCard 显示的分类
class QuickCategoryScreen extends ConsumerWidget {
  const QuickCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(timerCardCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('快捷分类'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategorySheet(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('暂无快捷分类', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('点击右上角添加', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '左滑删除，右滑设为默认',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _SwipeableCategoryItem(
                      key: ValueKey(category.id),
                      category: category,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _AddCategorySheet(),
    );
  }
}

/// 添加分类的底部弹窗
class _AddCategorySheet extends ConsumerWidget {
  const _AddCategorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategoriesAsync = ref.watch(categoriesProvider);
    final timerCardCategoriesAsync = ref.watch(timerCardCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择要添加的分类',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null),
          ),
          const SizedBox(height: 16),
          allCategoriesAsync.when(
            data: (allCategories) {
              return timerCardCategoriesAsync.when(
                data: (timerCardCategories) {
                  final timerCardIds = timerCardCategories.map((c) => c.id).toSet();
                  final availableCategories = allCategories
                      .where((c) => !timerCardIds.contains(c.id))
                      .toList();

                  if (availableCategories.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          '所有分类都已添加',
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableCategories.map((c) {
                      final color = _parseColor(c.color);
                      return GestureDetector(
                        onTap: () {
                          ref.read(categoryServiceProvider).setShowInTimerCard(c.id, true);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
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
                              const SizedBox(width: 8),
                              Text(
                                c.name,
                                style: TextStyle(color: color, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

/// 可滑动的分类项
class _SwipeableCategoryItem extends ConsumerStatefulWidget {
  final Category category;
  final bool isDark;

  const _SwipeableCategoryItem({super.key, required this.category, required this.isDark});

  @override
  ConsumerState<_SwipeableCategoryItem> createState() => _SwipeableCategoryItemState();
}

class _SwipeableCategoryItemState extends ConsumerState<_SwipeableCategoryItem> {
  double _dragExtent = 0;
  static const double _actionWidth = 80;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // 左滑最多露出删除按钮，右滑最多露出默认按钮
      _dragExtent = _dragExtent.clamp(-_actionWidth, _actionWidth);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // 滑动超过一半就停在按钮位置，否则回弹
    if (_dragExtent < -_actionWidth / 2) {
      setState(() => _dragExtent = -_actionWidth);
    } else if (_dragExtent > _actionWidth / 2) {
      setState(() => _dragExtent = _actionWidth);
    } else {
      setState(() => _dragExtent = 0);
    }
  }

  void _resetPosition() {
    setState(() => _dragExtent = 0);
  }

  void _handleDelete() {
    ref.read(categoryServiceProvider).setShowInTimerCard(widget.category.id, false);
  }

  void _handleSetDefault() {
    ref.read(categoryServiceProvider).setAsDefaultForTimerCard(widget.category.id);
    _resetPosition();
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.category.color);
    final isDefault = widget.category.isDefaultForTimerCard;
    final isDark = widget.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            // 左侧背景 - 绿色（设为默认）
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _actionWidth,
              child: GestureDetector(
                onTap: _handleSetDefault,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text('默认', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            // 右侧背景 - 红色（删除）
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
                onTap: _resetPosition,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isDefault
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.category.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : null),
                        ),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
