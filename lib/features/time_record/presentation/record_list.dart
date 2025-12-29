import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/time_record_provider.dart';
import '../../category/data/category_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/icon_picker.dart';

class RecordList extends ConsumerStatefulWidget {
  const RecordList({super.key});

  @override
  ConsumerState<RecordList> createState() => _RecordListState();
}

class _RecordListState extends ConsumerState<RecordList>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsByDateProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return recordsAsync.when(
      data: (records) {
        final completedRecords =
            records.where((r) => r.endTime != null).toList();

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: completedRecords.isEmpty
                ? const _EmptyState(key: ValueKey('empty'))
                : categoriesAsync.when(
                    data: (categories) {
                      final categoryMap = {for (var c in categories) c.id: c};
                      return ListView.separated(
                        key: const ValueKey('list'),
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: completedRecords.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final record = completedRecords[index];
                          final category = record.categoryId != null
                              ? categoryMap[record.categoryId]
                              : null;
                          return _RecordCard(
                            record: record,
                            category: category,
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('加载失败: $e')),
                  ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 64,
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '今天还没有记录',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            '开始记录你的时间吧',
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

// TimePad 风格任务卡片
class _RecordCard extends ConsumerWidget {
  final TimeRecord record;
  final Category? category;

  const _RecordCard({required this.record, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = record.endTime!.difference(record.startTime);
    final categoryColor =
        category != null ? _parseColor(category!.color) : const Color(0xFF8B5CF6);
    final textTheme = Theme.of(context).textTheme;
    
    // 监听当前计时中的任务
    final activeRecordAsync = ref.watch(activeRecordProvider);
    final activeRecord = activeRecordAsync.valueOrNull;
    // 判断当前这个卡片对应的事件是否正在计时（通过名称和分类匹配）
    final isThisRunning = activeRecord != null &&
        activeRecord.name == record.name &&
        activeRecord.categoryId == record.categoryId;

    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => _deleteRecord(context, ref),
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: Container(
        height: 84,
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
                    : Icons.access_time_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            // 中间+右侧内容
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 第一行：任务名 + 时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          record.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF000000),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4F4F4F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 第二行：标签 + 播放/暂停按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 标签：Personal（灰色）+ 分类（彩色）
                      Expanded(
                        child: Row(
                          children: [
                            // Personal 标签（灰色）
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Personal',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF828282),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 分类标签（彩色）
                            if (category != null)
                              _TagChip(
                                text: category!.name,
                                color: categoryColor,
                              ),
                          ],
                        ),
                      ),
                      // 播放/暂停按钮
                      GestureDetector(
                        onTap: () {
                          if (isThisRunning) {
                            // 当前这个事件正在计时，停止它
                            ref.read(timeRecordServiceProvider).stopTimer();
                          } else if (activeRecord != null) {
                            // 有其他事件在计时，先停止再开始这个
                            ref.read(timeRecordServiceProvider).stopTimer();
                            ref.read(timeRecordServiceProvider).startTimer(
                                  name: record.name,
                                  categoryId: record.categoryId,
                                );
                          } else {
                            // 没有计时中的任务，开始这个事件的计时
                            ref.read(timeRecordServiceProvider).startTimer(
                                  name: record.name,
                                  categoryId: record.categoryId,
                                );
                          }
                        },
                        child: Icon(
                          isThisRunning ? Icons.pause : Icons.play_arrow_outlined,
                          size: 24,
                          color: isThisRunning 
                              ? const Color(0xFF8B5CF6) 
                              : const Color(0xFF828282),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除「${record.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(timeRecordServiceProvider).deleteRecord(record.id);
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

// 标签组件
class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}
