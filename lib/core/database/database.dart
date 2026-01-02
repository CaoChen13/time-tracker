import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// 时间记录表
@TableIndex(name: 'idx_time_records_start_time', columns: {#startTime})
@TableIndex(name: 'idx_time_records_end_time', columns: {#endTime})
class TimeRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get icon => text().nullable()();  // 事件图标
  TextColumn get tags => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('timerCard'))();  // 来源: timerCard 或 quickAccess
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 分类表
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  IntColumn get dailyGoalMinutes => integer().nullable()();  // 每日目标（分钟）
  BoolColumn get showInTimerCard => boolean().withDefault(const Constant(false))();  // 是否显示在首页TimerCard
  BoolColumn get isDefaultForTimerCard => boolean().withDefault(const Constant(false))();  // 是否为TimerCard默认分类
}

// 事件模板表
@TableIndex(name: 'idx_event_templates_quick_access', columns: {#isQuickAccess})
class EventTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get icon => text().nullable()();  // 模板图标
  TextColumn get tags => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // 是否在快捷启动中显示
  BoolColumn get isQuickAccess => boolean().withDefault(const Constant(false))();
}

// 应用设置表
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

@DriftDatabase(tables: [TimeRecords, Categories, EventTemplates, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // 用于测试的构造函数
  AppDatabase.forTesting(super.e);

  // 保留静态单例用于兼容（逐步迁移后可移除）
  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(eventTemplates, eventTemplates.isQuickAccess);
          }
          if (from < 3) {
            await m.createIndex(Index('idx_time_records_start_time', 
              'CREATE INDEX idx_time_records_start_time ON time_records (start_time)'));
            await m.createIndex(Index('idx_time_records_end_time', 
              'CREATE INDEX idx_time_records_end_time ON time_records (end_time)'));
            await m.createIndex(Index('idx_event_templates_quick_access', 
              'CREATE INDEX idx_event_templates_quick_access ON event_templates (is_quick_access)'));
          }
          if (from < 4) {
            await m.addColumn(categories, categories.usageCount);
          }
          if (from < 5) {
            await m.createTable(appSettings);
          }
          if (from < 6) {
            await m.addColumn(categories, categories.dailyGoalMinutes);
          }
          if (from < 7) {
            await m.addColumn(timeRecords, timeRecords.icon);
          }
          if (from < 8) {
            await m.addColumn(eventTemplates, eventTemplates.icon);
          }
          if (from < 9) {
            await m.addColumn(categories, categories.showInTimerCard);
          }
          if (from < 10) {
            await m.addColumn(categories, categories.isDefaultForTimerCard);
          }
          if (from < 11) {
            await m.addColumn(timeRecords, timeRecords.source);
          }
        },
      );

  Future<void> init() async {
    await customSelect('SELECT 1').get();
  }

  // ========== 分类操作 ==========

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  // 按使用次数排序（常用分类）
  Stream<List<Category>> watchCategoriesByUsage() =>
      (select(categories)..orderBy([(t) => OrderingTerm.desc(t.usageCount)]))
          .watch();

  // 只获取显示在 TimerCard 的分类
  Stream<List<Category>> watchTimerCardCategories() =>
      (select(categories)
            ..where((t) => t.showInTimerCard.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.usageCount)]))
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

  // 增加分类使用次数
  Future<void> incrementCategoryUsage(int categoryId) async {
    await customStatement(
      'UPDATE categories SET usage_count = usage_count + 1 WHERE id = ?',
      [categoryId],
    );
  }

  // 设置分类是否显示在 TimerCard
  Future<void> setCategoryShowInTimerCard(int id, bool value) async {
    await (update(categories)..where((t) => t.id.equals(id)))
        .write(CategoriesCompanion(showInTimerCard: Value(value)));
    // 如果移除，同时取消默认
    if (!value) {
      await (update(categories)..where((t) => t.id.equals(id)))
          .write(const CategoriesCompanion(isDefaultForTimerCard: Value(false)));
    }
  }

  // 设置分类为 TimerCard 默认（只能有一个默认）
  Future<void> setCategoryAsDefaultForTimerCard(int id) async {
    // 先清除所有默认
    await customStatement('UPDATE categories SET is_default_for_timer_card = 0');
    // 设置新的默认
    await (update(categories)..where((t) => t.id.equals(id)))
        .write(const CategoriesCompanion(isDefaultForTimerCard: Value(true)));
  }

  // 获取 TimerCard 默认分类
  Future<Category?> getDefaultTimerCardCategory() async {
    return (select(categories)..where((t) => t.isDefaultForTimerCard.equals(true)))
        .getSingleOrNull();
  }

  // ========== 事件模板操作 ==========

  Stream<List<EventTemplate>> watchAllTemplates() =>
      (select(eventTemplates)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  // 只获取快捷启动的模板
  Stream<List<EventTemplate>> watchQuickAccessTemplates() =>
      (select(eventTemplates)
            ..where((t) => t.isQuickAccess.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<EventTemplate>> getAllTemplates() =>
      (select(eventTemplates)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<int> insertTemplate(EventTemplatesCompanion template) =>
      into(eventTemplates).insert(template);

  // 根据名称查找模板（只按名称，不管分类）
  Future<EventTemplate?> findTemplateByName(String name) =>
      (select(eventTemplates)..where((t) => t.name.equals(name)))
          .getSingleOrNull();

  // 根据名称和分类查找模板
  Future<EventTemplate?> findTemplate(String name, int? categoryId) =>
      (select(eventTemplates)
            ..where((t) => t.name.equals(name))
            ..where((t) => categoryId != null 
                ? t.categoryId.equals(categoryId) 
                : t.categoryId.isNull()))
          .getSingleOrNull();

  Future<bool> updateTemplate(EventTemplate template) =>
      update(eventTemplates).replace(template);

  Future<int> deleteTemplate(int id) =>
      (delete(eventTemplates)..where((t) => t.id.equals(id))).go();

  // 设置模板的快捷启动状态
  Future<void> setQuickAccess(int id, bool value) async {
    await (update(eventTemplates)..where((t) => t.id.equals(id)))
        .write(EventTemplatesCompanion(isQuickAccess: Value(value)));
  }

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

  // ========== 应用设置操作 ==========

  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((s) => s?.value);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'time_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
