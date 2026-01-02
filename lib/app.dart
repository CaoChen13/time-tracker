import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/settings_provider.dart';

class TimeTrackerApp extends ConsumerWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appThemeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Time Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _convertThemeMode(appThemeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeMode _convertThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system: return ThemeMode.system;
      case AppThemeMode.light: return ThemeMode.light;
      case AppThemeMode.dark: return ThemeMode.dark;
    }
  }
}
