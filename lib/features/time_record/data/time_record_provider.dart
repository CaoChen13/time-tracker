import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

// 当前选中的日期
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 当天的记录
final recordsByDateProvider = StreamProvider<List<TimeRecord>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return AppDatabase.instance.watchRecordsByDate(date);
});

// 正在进行的记录
final activeRecordProvider = StreamProvider<TimeRecord?>((ref) {
  return AppDatabase.instance.watchActiveRecord();
});

final timeRecordServiceProvider = Provider((ref) => TimeRecordService());

class TimeRecordService {
  final _db = AppDatabase.instance;

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
