import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

// 全部模板
final templatesProvider = StreamProvider<List<EventTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTemplates();
});

// 快捷启动模板
final quickAccessTemplatesProvider = StreamProvider<List<EventTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchQuickAccessTemplates();
});

final templateServiceProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return TemplateService(db);
});

class TemplateService {
  final AppDatabase _db;

  TemplateService(this._db);

  Future<int> addTemplate({
    required String name,
    int? categoryId,
    String? tags,
    bool isQuickAccess = false,
  }) {
    return _db.insertTemplate(EventTemplatesCompanion.insert(
      name: name,
      categoryId: Value(categoryId),
      tags: Value(tags),
      isQuickAccess: Value(isQuickAccess),
    ));
  }

  Future<bool> updateTemplate(EventTemplate template) {
    return _db.updateTemplate(template);
  }

  Future<int> deleteTemplate(int id) {
    return _db.deleteTemplate(id);
  }

  // 设置快捷启动状态
  Future<void> setQuickAccess(int id, bool value) {
    return _db.setQuickAccess(id, value);
  }
}
