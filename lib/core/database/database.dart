import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// 时间记录表
class TimeRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 分类表
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// 事件模板表
class EventTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get tags => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [TimeRecords, Categories, EventTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 1;

  Future<void> init() async {
    await customSelect('SELECT 1').get();
  }

  // ========== 分类操作 ==========

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  // ========== 时间记录操作 ==========

  Stream<List<TimeRecord>> watchRecordsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(timeRecords)
          ..where((t) =>
              t.startTime.isBiggerOrEqualValue(start) &
              t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }

  Stream<TimeRecord?> watchActiveRecord() =>
      (select(timeRecords)..where((t) => t.endTime.isNull()))
          .watchSingleOrNull();

  Future<TimeRecord?> getActiveRecord() =>
      (select(timeRecords)..where((t) => t.endTime.isNull())).getSingleOrNull();

  Future<int> insertRecord(TimeRecordsCompanion record) =>
      into(timeRecords).insert(record);

  Future<bool> updateRecord(TimeRecord record) =>
      update(timeRecords).replace(record);

  Future<int> deleteRecord(int id) =>
      (delete(timeRecords)..where((t) => t.id.equals(id))).go();

  Future<void> stopActiveRecord() async {
    final active = await getActiveRecord();
    if (active != null) {
      await updateRecord(active.copyWith(endTime: Value(DateTime.now())));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'time_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
