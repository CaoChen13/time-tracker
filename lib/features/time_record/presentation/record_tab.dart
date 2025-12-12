import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/time_record_provider.dart';
import 'timer_card.dart';
import 'record_list.dart';
import 'add_record_sheet.dart';

class RecordTab extends ConsumerWidget {
  const RecordTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期头部
            _DateHeader(date: selectedDate),
            // 计时器卡片
            const TimerCard(),
            // 记录列表标题
            const _RecordListHeader(),
            // 记录列表
            const Expanded(child: RecordList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRecordSheet(),
    );
  }
}

class _DateHeader extends ConsumerWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final formatter = DateFormat('M月d日E', 'zh_CN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'TODAY' : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state =
                            date.subtract(const Duration(days: 1));
                      },
                      child: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      formatter.format(date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: isToday
                          ? null
                          : () {
                              ref.read(selectedDateProvider.notifier).state =
                                  date.add(const Duration(days: 1));
                            },
                      child: Icon(
                        Icons.chevron_right,
                        color: isToday
                            ? theme.colorScheme.outline.withOpacity(0.3)
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 深色模式切换按钮（占位）
          IconButton(
            onPressed: () => _selectDate(context, ref),
            icon: Icon(
              Icons.calendar_month_outlined,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _RecordListHeader extends ConsumerWidget {
  const _RecordListHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(recordsByDateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '今日记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          recordsAsync.when(
            data: (records) {
              final completed = records.where((r) => r.endTime != null).toList();
              final totalDuration = completed.fold<Duration>(
                Duration.zero,
                (sum, r) => sum + r.endTime!.difference(r.startTime),
              );
              return Text(
                '总计: ${_formatDuration(totalDuration)}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.outline,
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
