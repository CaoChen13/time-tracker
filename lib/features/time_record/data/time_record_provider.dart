import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

// 当前选中的日期
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 当天的记录
final recordsByDateProvider = StreamProvider<List<TimeRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.watchRecordsByDate(date);
});

// 正在进行的记录
final activeRecordProvider = StreamProvider<TimeRecord?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveRecord();
});

final timeRecordServiceProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return TimeRecordService(db);
});

class TimeRecordService {
  final AppDatabase _db;

  TimeRecordService(this._db);

  // 开始计时
  Future<int> startTimer({
    required String name,
    int? categoryId,
    String? tags,
  }) async {
    // 先停止之前的记录
    await _db.stopActiveRecord();

    return _db.insertRecord(TimeRecordsCompanion.insert(
      name: name,
      startTime: DateTime.now(),
      categoryId: Value(categoryId),
      tags: Value(tags),
    ));
  }

  // 停止计时
  Future<void> stopTimer() {
    return _db.stopActiveRecord();
  }

  // 取消计时（不保存）
  Future<void> cancelTimer() async {
    final active = await _db.getActiveRecord();
    if (active != null) {
      await _db.deleteRecord(active.id);
    }
  }

  // 手动添加记录
  Future<int> addRecord({
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    int? categoryId,
    String? tags,
    String? note,
  }) {
    return _db.insertRecord(TimeRecordsCompanion.insert(
      name: name,
      startTime: startTime,
      endTime: Value(endTime),
      categoryId: Value(categoryId),
      tags: Value(tags),
      note: Value(note),
    ));
  }

  // 更新记录
  Future<bool> updateRecord(TimeRecord record) {
    return _db.updateRecord(record);
  }

  // 删除记录
  Future<int> deleteRecord(int id) {
    return _db.deleteRecord(id);
  }
}
