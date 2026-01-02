import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../data/time_record_provider.dart';
import '../../template/data/template_provider.dart';
import '../../template/presentation/template_edit_sheet.dart';
import '../../category/data/category_provider.dart';
import '../../statistics/data/statistics_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';

/// 首页模板列表 - 只显示快捷启动的模板
class TemplateList extends ConsumerWidget {
  const TemplateList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用快捷启动模板
    final templatesAsync = ref.watch(quickAccessTemplatesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final activeRecordAsync = ref.watch(activeRecordProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return const _EmptyState();
        }

        return categoriesAsync.when(
          data: (categories) {
            final categoryMap = {for (var c in categories) c.id: c};
            final activeRecord = activeRecordAsync.valueOrNull;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = templates[index];
                final category = template.categoryId != null
                    ? categoryMap[template.categoryId]
                    : null;
                // 判断这个模板是否正在计时
                final isThisRunning = activeRecord != null &&
                    activeRecord.name == template.name &&
                    activeRecord.categoryId == template.categoryId;

                return _TemplateCard(
                  template: template,
                  category: category,
                  isThisRunning: isThisRunning,
                  hasActiveTimer: activeRecord != null,
                  activeStartTime: isThisRunning ? activeRecord.startTime : null,
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            size: 64,
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无事件模板',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方添加常用事件',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模板卡片 - 左滑删除，右侧播放按钮
class _TemplateCard extends ConsumerStatefulWidget {
  final EventTemplate template;
  final Category? category;
  final bool isThisRunning;
  final bool hasActiveTimer;
  final DateTime? activeStartTime;

  const _TemplateCard({
    required this.template,
    this.category,
    required this.isThisRunning,
    required this.hasActiveTimer,
    this.activeStartTime,
  });

  @override
  ConsumerState<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends ConsumerState<_TemplateCard> {
  double _dragExtent = 0;
  static const double _actionWidth = 80;
  bool _isPlayPressed = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // 只允许左滑
      _dragExtent = _dragExtent.clamp(-_actionWidth, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent < -_actionWidth / 2) {
      setState(() => _dragExtent = -_actionWidth);
    } else {
      setState(() => _dragExtent = 0);
    }
  }

  void _resetPosition() {
    setState(() => _dragExtent = 0);
  }

  void _handleDelete() {
    // 如果正在计时，先停止
    if (widget.isThisRunning) {
      ref.read(timeRecordServiceProvider).stopTimer();
      ref.read(statisticsRefreshProvider.notifier).state++;
    }
    // 从快捷启动移除
    ref.read(templateServiceProvider).setQuickAccess(widget.template.id, false);
  }

  void _handlePlayPause() {
    if (widget.isThisRunning) {
      ref.read(timeRecordServiceProvider).stopTimer();
      ref.read(statisticsRefreshProvider.notifier).state++;
    } else if (widget.hasActiveTimer) {
      ref.read(timeRecordServiceProvider).stopTimer();
      ref.read(statisticsRefreshProvider.notifier).state++;
      ref.read(timeRecordServiceProvider).startTimer(
            name: widget.template.name,
            categoryId: widget.template.categoryId,
            icon: widget.template.icon,
            source: 'quickAccess',
          );
    } else {
      ref.read(timeRecordServiceProvider).startTimer(
            name: widget.template.name,
            categoryId: widget.template.categoryId,
            icon: widget.template.icon,
            source: 'quickAccess',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category != null 
        ? _parseColor(widget.category!.color) 
        : AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final playBtnBg = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final playBtnIconColor = isDark ? Colors.grey.shade400 : const Color(0xFF9CA3AF);

    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          // 右侧背景 - 红色删除按钮（只在滑动时显示）
          if (_dragExtent < 0)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _actionWidth,
              child: GestureDetector(
                onTap: _handleDelete,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text('删除', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // 左侧图标
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: IconDisplay(icon: widget.template.icon, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 中间内容
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.template.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // 计时显示或分类标签
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: widget.isThisRunning && widget.activeStartTime != null
                                ? _TimerDisplay(key: const ValueKey('timer'), startTime: widget.activeStartTime!)
                                : widget.category != null
                                    ? Text(
                                        widget.category!.name,
                                        key: ValueKey('cat_${widget.category!.id}'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: categoryColor,
                                        ),
                                      )
                                    : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ],
                      ),
                    ),
                    // 播放按钮 - 带缩放动画
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPlayPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPlayPressed = false);
                        _handlePlayPause();
                      },
                      onTapCancel: () => setState(() => _isPlayPressed = false),
                      child: AnimatedScale(
                        scale: _isPlayPressed ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.isThisRunning || _isPlayPressed
                                ? AppColors.primary
                                : playBtnBg,
                            shape: BoxShape.circle,
                            boxShadow: widget.isThisRunning || _isPlayPressed
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            widget.isThisRunning ? Icons.pause : Icons.play_arrow,
                            size: 20,
                            color: widget.isThisRunning || _isPlayPressed
                                ? Colors.white
                                : playBtnIconColor,
                          ),
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

// 计时显示组件
class _TimerDisplay extends StatelessWidget {
  final DateTime startTime;

  const _TimerDisplay({super.key, required this.startTime});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final duration = DateTime.now().difference(startTime);
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        return Text(
          '$hours:$minutes:$seconds',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        );
      },
    );
  }
}
