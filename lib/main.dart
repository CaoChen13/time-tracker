import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化中文日期格式
  await initializeDateFormatting('zh_CN');
  
  // 初始化数据库
  await AppDatabase.instance.init();
  
  runApp(
    const ProviderScope(
      child: TimeTrackerApp(),
    ),
  );
}
