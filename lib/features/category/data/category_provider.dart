import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

final categoryServiceProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryService(db);
});

class CategoryService {
  final AppDatabase _db;

  CategoryService(this._db);

  Future<int> addCategory({
    required String name,
    required String color,
    String? icon,
  }) {
    return _db.insertCategory(CategoriesCompanion.insert(
      name: name,
      color: color,
      icon: Value(icon),
    ));
  }

  Future<bool> updateCategory(Category category) {
    return _db.updateCategory(category);
  }

  Future<int> deleteCategory(int id) {
    return _db.deleteCategory(id);
  }
}
