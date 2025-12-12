import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return AppDatabase.instance.watchAllCategories();
});

final categoryServiceProvider = Provider((ref) => CategoryService());

class CategoryService {
  final _db = AppDatabase.instance;

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
