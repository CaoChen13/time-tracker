import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

// 主题模式
enum AppThemeMode { system, light, dark }

// 主题状态
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('themeMode') ?? 0;
    state = AppThemeMode.values[index];
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }
}

// 数据管理服务
final dataManagementProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return DataManagementService(db);
});

class DataManagementService {
  final AppDatabase _db;
  static const String _exportVersion = '1.0';
  static const String _appIdentifier = 'time_tracker_app';

  DataManagementService(this._db);

  // 导出数据
  Future<String?> exportData() async {
    try {
      // 获取所有数据
      final categories = await _db.select(_db.categories).get();
      final templates = await _db.select(_db.eventTemplates).get();
      final records = await _db.select(_db.timeRecords).get();

      final data = {
        'appIdentifier': _appIdentifier,
        'version': _exportVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => {
          'id': c.id,
          'name': c.name,
          'color': c.color,
          'icon': c.icon,
          'usageCount': c.usageCount,
          'showInTimerCard': c.showInTimerCard,
          'isDefaultForTimerCard': c.isDefaultForTimerCard,
        }).toList(),
        'templates': templates.map((t) => {
          'id': t.id,
          'name': t.name,
          'categoryId': t.categoryId,
          'icon': t.icon,
          'tags': t.tags,
          'sortOrder': t.sortOrder,
          'isQuickAccess': t.isQuickAccess,
        }).toList(),
        'records': records.map((r) => {
          'id': r.id,
          'name': r.name,
          'startTime': r.startTime.toIso8601String(),
          'endTime': r.endTime?.toIso8601String(),
          'categoryId': r.categoryId,
          'tags': r.tags,
          'note': r.note,
          'icon': r.icon,
          'source': r.source,
        }).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      
      // 保存到临时文件
      final dir = await getTemporaryDirectory();
      final fileName = 'time_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      // 分享文件
      await Share.shareXFiles([XFile(file.path)], text: '时间追踪数据备份');
      
      return null; // 成功
    } catch (e) {
      return '导出失败: $e';
    }
  }

  // 导入数据，返回: null=成功, 'cancelled'=用户取消, 其他=错误信息
  Future<String?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return 'cancelled'; // 用户取消
      }

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 验证数据格式
      if (data['appIdentifier'] != _appIdentifier) {
        return '无效的备份文件，只能导入本软件导出的数据';
      }

      // 清除现有数据
      await _db.delete(_db.timeRecords).go();
      await _db.delete(_db.eventTemplates).go();
      await _db.delete(_db.categories).go();

      // 导入分类
      final categories = data['categories'] as List;
      for (final c in categories) {
        await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          name: c['name'],
          color: c['color'],
          icon: Value(c['icon']),
          usageCount: Value(c['usageCount'] ?? 0),
          showInTimerCard: Value(c['showInTimerCard'] ?? false),
          isDefaultForTimerCard: Value(c['isDefaultForTimerCard'] ?? false),
        ));
      }

      // 导入模板
      final templates = data['templates'] as List;
      for (final t in templates) {
        await _db.into(_db.eventTemplates).insert(EventTemplatesCompanion.insert(
          name: t['name'],
          categoryId: Value(t['categoryId']),
          icon: Value(t['icon']),
          tags: Value(t['tags']),
          sortOrder: Value(t['sortOrder'] ?? 0),
          isQuickAccess: Value(t['isQuickAccess'] ?? false),
        ));
      }

      // 导入记录
      final records = data['records'] as List;
      for (final r in records) {
        await _db.into(_db.timeRecords).insert(TimeRecordsCompanion.insert(
          name: r['name'],
          startTime: DateTime.parse(r['startTime']),
          endTime: Value(r['endTime'] != null ? DateTime.parse(r['endTime']) : null),
          categoryId: Value(r['categoryId']),
          tags: Value(r['tags']),
          note: Value(r['note']),
          icon: Value(r['icon']),
          source: Value(r['source']),
        ));
      }

      return null; // 成功
    } catch (e) {
      return '导入失败: $e';
    }
  }

  // 清除所有数据
  Future<String?> clearAllData() async {
    try {
      await _db.delete(_db.timeRecords).go();
      await _db.delete(_db.eventTemplates).go();
      await _db.delete(_db.categories).go();
      return null;
    } catch (e) {
      return '清除失败: $e';
    }
  }
}
