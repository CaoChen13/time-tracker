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
    String? icon,
    String? tags,
    String? color,
    bool isQuickAccess = false,
  }) {
    return _db.insertTemplate(EventTemplatesCompanion.insert(
      name: name,
      categoryId: Value(categoryId),
      icon: Value(icon),
      tags: Value(color ?? tags), // 用 tags 存颜色
      isQuickAccess: Value(isQuickAccess),
    ));
  }

  // 查找模板（只按名称）
  Future<EventTemplate?> findTemplateByName(String name) {
    return _db.findTemplateByName(name);
  }

  // 查找模板（按名称和分类）
  Future<EventTemplate?> findTemplate(String name, int? categoryId) {
    return _db.findTemplate(name, categoryId);
  }

  // 确保模板存在（只按名称检查，不存在则创建）
  Future<void> ensureTemplateExists({
    required String name,
    int? categoryId,
    bool isQuickAccess = true,
  }) async {
    final existing = await findTemplateByName(name);
    if (existing == null) {
      await addTemplate(
        name: name,
        categoryId: categoryId,
        isQuickAccess: isQuickAccess,
      );
    }
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
