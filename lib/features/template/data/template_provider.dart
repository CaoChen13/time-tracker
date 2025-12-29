import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

// 全部模板
final templatesProvider = StreamProvider<List<EventTemplate>>((ref) {
  return AppDatabase.instance.watchAllTemplates();
});

// 快捷启动模板
final quickAccessTemplatesProvider = StreamProvider<List<EventTemplate>>((ref) {
  return AppDatabase.instance.watchQuickAccessTemplates();
});

final templateServiceProvider = Provider((ref) => TemplateService());

class TemplateService {
  final _db = AppDatabase.instance;

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
