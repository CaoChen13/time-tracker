import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/time_record_provider.dart';
import '../../category/data/category_provider.dart';
import '../../../core/database/database.dart';

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
                            const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: completedRecords.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
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

// 记录卡片 - 长按删除
class _RecordCard extends ConsumerWidget {
  final TimeRecord record;
  final Category? category;

  const _RecordCard({required this.record, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final duration = record.endTime!.difference(record.startTime);
    final categoryColor =
        category != null ? _parseColor(category!.color) : Colors.grey;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左侧彩色条
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // 内容区
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (category != null) ...[
                                  Icon(
                                    Icons.label_outline,
                                    size: 14,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    category!.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: categoryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${timeFormat.format(record.startTime)} - ${timeFormat.format(record.endTime!)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 时长
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
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
              foregroundColor: Theme.of(context).colorScheme.error,
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
      return Colors.grey;
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
