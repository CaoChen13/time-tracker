import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 主色调 Indigo
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryDark = Color(0xFF4F46E5);
  
  // 中文字体回退列表
  static const _chineseFontFallback = ['PingFang SC', 'Heiti SC', 'Microsoft YaHei', 'sans-serif'];

  // 创建带中文回退的文字样式
  static TextStyle _withChineseFallback(TextStyle style) {
    return style.copyWith(fontFamilyFallback: _chineseFontFallback);
  }

  static ThemeData get light {
    // 获取 Poppins 主题并添加中文回退
    final poppinsTheme = GoogleFonts.poppinsTextTheme();
    final textTheme = poppinsTheme.copyWith(
      displayLarge: _withChineseFallback(poppinsTheme.displayLarge!),
      displayMedium: _withChineseFallback(poppinsTheme.displayMedium!),
      displaySmall: _withChineseFallback(poppinsTheme.displaySmall!),
      headlineLarge: _withChineseFallback(poppinsTheme.headlineLarge!),
      headlineMedium: _withChineseFallback(poppinsTheme.headlineMedium!),
      headlineSmall: _withChineseFallback(poppinsTheme.headlineSmall!),
      titleLarge: _withChineseFallback(poppinsTheme.titleLarge!),
      titleMedium: _withChineseFallback(poppinsTheme.titleMedium!),
      titleSmall: _withChineseFallback(poppinsTheme.titleSmall!),
      bodyLarge: _withChineseFallback(poppinsTheme.bodyLarge!),
      bodyMedium: _withChineseFallback(poppinsTheme.bodyMedium!),
      bodySmall: _withChineseFallback(poppinsTheme.bodySmall!),
      labelLarge: _withChineseFallback(poppinsTheme.labelLarge!),
      labelMedium: _withChineseFallback(poppinsTheme.labelMedium!),
      labelSmall: _withChineseFallback(poppinsTheme.labelSmall!),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: const Color(0xFF1F2937),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: _primaryColor.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryColor);
          }
          return IconThemeData(color: Colors.grey.shade600);
        }),
      ),
    );
  }

  static ThemeData get dark {
    // 获取 Poppins 主题并添加中文回退
    final poppinsTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);
    final textTheme = poppinsTheme.copyWith(
      displayLarge: _withChineseFallback(poppinsTheme.displayLarge!),
      displayMedium: _withChineseFallback(poppinsTheme.displayMedium!),
      displaySmall: _withChineseFallback(poppinsTheme.displaySmall!),
      headlineLarge: _withChineseFallback(poppinsTheme.headlineLarge!),
      headlineMedium: _withChineseFallback(poppinsTheme.headlineMedium!),
      headlineSmall: _withChineseFallback(poppinsTheme.headlineSmall!),
      titleLarge: _withChineseFallback(poppinsTheme.titleLarge!),
      titleMedium: _withChineseFallback(poppinsTheme.titleMedium!),
      titleSmall: _withChineseFallback(poppinsTheme.titleSmall!),
      bodyLarge: _withChineseFallback(poppinsTheme.bodyLarge!),
      bodyMedium: _withChineseFallback(poppinsTheme.bodyMedium!),
      bodySmall: _withChineseFallback(poppinsTheme.bodySmall!),
      labelLarge: _withChineseFallback(poppinsTheme.labelLarge!),
      labelMedium: _withChineseFallback(poppinsTheme.labelMedium!),
      labelSmall: _withChineseFallback(poppinsTheme.labelSmall!),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF111827),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1F2937),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        indicatorColor: _primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryColor);
          }
          return IconThemeData(color: Colors.grey.shade400);
        }),
      ),
    );
  }
}
