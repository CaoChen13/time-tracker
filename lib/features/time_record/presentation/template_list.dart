import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/time_record_provider.dart';
import '../../template/data/template_provider.dart';
import '../../category/data/category_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';

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

/// 模板卡片 - 简洁单行样式，右边两个圆形按钮
class _TemplateCard extends ConsumerWidget {
  final EventTemplate template;
  final Category? category;
  final bool isThisRunning;
  final bool hasActiveTimer;

  const _TemplateCard({
    required this.template,
    this.category,
    required this.isThisRunning,
    required this.hasActiveTimer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = category != null
        ? _parseColor(category!.color)
        : const Color(0xFF8B5CF6);

    // 获取当前计时的开始时间
    final activeRecordAsync = ref.watch(activeRecordProvider);
    final activeRecord = activeRecordAsync.valueOrNull;
    final startTime = isThisRunning ? activeRecord?.startTime : null;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 左侧圆形图标
          Container(
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
              size: 22,
              color: Colors.white,
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
                  template.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF000000),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 计时显示或分类标签
                if (isThisRunning && startTime != null)
                  _TimerDisplay(startTime: startTime)
                else if (category != null)
                  _TagChip(text: category!.name, color: categoryColor),
              ],
            ),
          ),
          // 右侧按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 播放/暂停按钮
              GestureDetector(
                onTap: () => _handlePlayPause(ref),
                child: Icon(
                  isThisRunning ? Icons.pause_circle_filled : Icons.play_circle_outline,
                  size: 32,
                  color: isThisRunning
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF828282),
                ),
              ),
              const SizedBox(width: 8),
              // 终止按钮 - 使用 Container 绘制圆环以匹配播放按钮大小
              GestureDetector(
                onTap: () => _handleRemove(ref),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 圆环边框
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF828282),
                            width: 2,
                          ),
                        ),
                      ),
                      // 红色方块
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePlayPause(WidgetRef ref) {
    if (isThisRunning) {
      // 暂停：停止计时并保存记录
      ref.read(timeRecordServiceProvider).stopTimer();
    } else if (hasActiveTimer) {
      // 有其他事件在计时，先停止再开始这个
      ref.read(timeRecordServiceProvider).stopTimer();
      ref.read(timeRecordServiceProvider).startTimer(
            name: template.name,
            categoryId: template.categoryId,
          );
    } else {
      // 开始计时
      ref.read(timeRecordServiceProvider).startTimer(
            name: template.name,
            categoryId: template.categoryId,
          );
    }
  }

  void _handleRemove(WidgetRef ref) {
    // 如果正在计时，先停止
    if (isThisRunning) {
      ref.read(timeRecordServiceProvider).stopTimer();
    }
    // 从快捷启动移除
    ref.read(templateServiceProvider).setQuickAccess(template.id, false);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }
}

// 计时显示组件
class _TimerDisplay extends StatelessWidget {
  final DateTime startTime;

  const _TimerDisplay({required this.startTime});

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
            color: const Color(0xFF8B5CF6),
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}
