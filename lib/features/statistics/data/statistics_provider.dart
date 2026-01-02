import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

// 统计刷新通知器 - 计时结束时 +1 触发刷新
final statisticsRefreshProvider = StateProvider<int>((ref) => 0);

// 时间范围类型
enum DateRangeType { day, week, month, year }

// 范围参数
class RangeParams {
  final DateTime date;
  final DateRangeType rangeType;
  
  RangeParams(this.date, this.rangeType);
  
  @override
  bool operator ==(Object other) =>
      other is RangeParams && date == other.date && rangeType == other.rangeType;
  
  @override
  int get hashCode => date.hashCode ^ rangeType.hashCode;
}

// 获取范围的开始和结束时间
(DateTime, DateTime) getDateRange(DateTime date, DateRangeType rangeType) {
  switch (rangeType) {
    case DateRangeType.day:
      final start = DateTime(date.year, date.month, date.day);
      return (start, start.add(const Duration(days: 1)));
    case DateRangeType.week:
      // 周一为一周开始
      final weekday = date.weekday;
      final start = DateTime(date.year, date.month, date.day - weekday + 1);
      return (start, start.add(const Duration(days: 7)));
    case DateRangeType.month:
      final start = DateTime(date.year, date.month, 1);
      final end = DateTime(date.year, date.month + 1, 1);
      return (start, end);
    case DateRangeType.year:
      final start = DateTime(date.year, 1, 1);
      final end = DateTime(date.year + 1, 1, 1);
      return (start, end);
  }
}

// 按日期获取记录（单日，按开始时间升序）
final recordsByDateProvider = FutureProvider.family<List<TimeRecord>, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  
  return (db.select(db.timeRecords)
        ..where((t) => t.startTime.isBiggerOrEqualValue(start))
        ..where((t) => t.startTime.isSmallerThanValue(end))
        ..where((t) => t.endTime.isNotNull())
        ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
      .get();
});


// 按范围获取记录（周/月/年，按开始时间降序，最新的在前）
final recordsByRangeProvider = FutureProvider.family<List<TimeRecord>, RangeParams>((ref, params) async {
  // 监听刷新通知
  ref.watch(statisticsRefreshProvider);
  
  final db = ref.watch(databaseProvider);
  final (start, end) = getDateRange(params.date, params.rangeType);
  
  return (db.select(db.timeRecords)
        ..where((t) => t.startTime.isBiggerOrEqualValue(start))
        ..where((t) => t.startTime.isSmallerThanValue(end))
        ..where((t) => t.endTime.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
      .get();
});

// 按范围获取分类统计
final statsByRangeProvider = FutureProvider.family<Map<int?, Duration>, RangeParams>((ref, params) async {
  final records = await ref.watch(recordsByRangeProvider(params).future);
  
  final stats = <int?, Duration>{};
  for (final record in records) {
    if (record.endTime != null) {
      final duration = record.endTime!.difference(record.startTime);
      final categoryId = record.categoryId;
      stats[categoryId] = (stats[categoryId] ?? Duration.zero) + duration;
    }
  }
  return stats;
});

// 按范围获取总时长
final totalByRangeProvider = FutureProvider.family<Duration, RangeParams>((ref, params) async {
  final stats = await ref.watch(statsByRangeProvider(params).future);
  return stats.values.fold<Duration>(Duration.zero, (a, b) => a + b);
});

// 按日期获取分类统计（单日，兼容旧代码）
final dailyStatsProvider = FutureProvider.family<Map<int?, Duration>, DateTime>((ref, date) async {
  final records = await ref.watch(recordsByDateProvider(date).future);
  
  final stats = <int?, Duration>{};
  for (final record in records) {
    if (record.endTime != null) {
      final duration = record.endTime!.difference(record.startTime);
      final categoryId = record.categoryId;
      stats[categoryId] = (stats[categoryId] ?? Duration.zero) + duration;
    }
  }
  return stats;
});

// 获取当天总时长（兼容旧代码）
final dailyTotalProvider = FutureProvider.family<Duration, DateTime>((ref, date) async {
  final stats = await ref.watch(dailyStatsProvider(date).future);
  return stats.values.fold<Duration>(Duration.zero, (a, b) => a + b);
});

// 按日期分组记录
Map<DateTime, List<TimeRecord>> groupRecordsByDate(List<TimeRecord> records) {
  final grouped = <DateTime, List<TimeRecord>>{};
  for (final record in records) {
    final date = DateTime(record.startTime.year, record.startTime.month, record.startTime.day);
    grouped.putIfAbsent(date, () => []).add(record);
  }
  return grouped;
}

// 计算每天的总时长
Map<DateTime, Duration> calculateDailyTotals(Map<DateTime, List<TimeRecord>> grouped) {
  final totals = <DateTime, Duration>{};
  for (final entry in grouped.entries) {
    Duration total = Duration.zero;
    for (final record in entry.value) {
      if (record.endTime != null) {
        total += record.endTime!.difference(record.startTime);
      }
    }
    totals[entry.key] = total;
  }
  return totals;
}
