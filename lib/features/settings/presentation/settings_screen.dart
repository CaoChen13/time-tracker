import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题设置
          _SettingsSection(
            title: '外观',
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: '主题模式',
                subtitle: _getThemeModeText(themeMode),
                onTap: () => _showThemeDialog(context, ref, themeMode),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 数据管理
          _SettingsSection(
            title: '数据管理',
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: '导出数据',
                subtitle: '备份为 JSON 文件',
                onTap: () => _handleExport(context, ref),
                isDark: isDark,
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: '导入数据',
                subtitle: '只能导入本软件导出的数据',
                onTap: () => _handleImport(context, ref),
                isDark: isDark,
              ),
              _SettingsTile(
                icon: Icons.delete_outline,
                title: '清除数据',
                subtitle: '删除所有记录',
                onTap: () => _showClearDataDialog(context, ref),
                isDestructive: true,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 关于
          _SettingsSection(
            title: '关于',
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '版本',
                subtitle: '1.0.0',
                onTap: null,
                isDark: isDark,
              ),
              _SettingsTile(
                icon: Icons.code_outlined,
                title: '开源协议',
                subtitle: 'MIT License',
                onTap: () => _showLicenseDialog(context),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system: return '跟随系统';
      case AppThemeMode.light: return '浅色模式';
      case AppThemeMode.dark: return '深色模式';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) => 
            _ThemeOption(
              title: _getThemeModeText(mode),
              isSelected: mode == current,
              onTap: () {
                ref.read(themeModeProvider.notifier).setTheme(mode);
                Navigator.pop(ctx);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final service = ref.read(dataManagementProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await service.exportData();
    
    if (context.mounted) Navigator.pop(context);

    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    // 先确认
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入将覆盖现有数据，确定继续吗？\n\n注意：只能导入本软件导出的备份文件。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('继续')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final service = ref.read(dataManagementProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.importData();
    
    if (context.mounted) Navigator.pop(context);

    if (context.mounted && result != 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? '导入成功'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('确定要删除所有数据吗？此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final service = ref.read(dataManagementProvider);
              final error = await service.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? '数据已清除'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showLicensePage(context: context, applicationName: '时间追踪', applicationVersion: '1.0.0');
  }
}


class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SettingsSection({required this.title, required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(children.length * 2 - 1, (index) {
              if (index.isOdd) return Divider(height: 1, indent: 52, color: isDark ? Colors.grey.shade700 : Colors.grey.shade200);
              return children[index ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.primary;
    final textColor = isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}
