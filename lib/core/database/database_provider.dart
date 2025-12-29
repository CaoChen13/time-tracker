import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

/// 数据库 Provider - 用于依赖注入
/// 使用方式: ref.watch(databaseProvider)
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
