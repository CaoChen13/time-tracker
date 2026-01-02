import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

// 按使用次数排序的分类（常用分类）
final categoriesByUsageProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCategoriesByUsage();
});

// 显示在 TimerCard 的分类
final timerCardCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTimerCardCategories();
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

  // 增加使用次数
  Future<void> incrementUsage(int categoryId) {
    return _db.incrementCategoryUsage(categoryId);
  }

  // 设置分类是否显示在 TimerCard
  Future<void> setShowInTimerCard(int id, bool value) {
    return _db.setCategoryShowInTimerCard(id, value);
  }

  // 设置分类为 TimerCard 默认
  Future<void> setAsDefaultForTimerCard(int id) {
    return _db.setCategoryAsDefaultForTimerCard(id);
  }

  // 获取 TimerCard 默认分类
  Future<Category?> getDefaultTimerCardCategory() {
    return _db.getDefaultTimerCardCategory();
  }
}
