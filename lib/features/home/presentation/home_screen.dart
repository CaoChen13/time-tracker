import 'package:flutter/material.dart';
import '../../time_record/presentation/record_tab.dart';
import '../../time_record/presentation/add_record_sheet.dart';
import '../../category/presentation/category_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          RecordTab(),
          _StatisticsTab(),
        ],
      ),
      bottomNavigationBar: _TimePadBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// 统计页面（待实现）
class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '统计功能开发中',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 目标页面（待实现）
class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.track_changes_outlined,
                size: 64,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '目标功能开发中',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 设置页面
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '设置',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.folder_outlined,
                    title: '分类管理',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryListScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: '主题设置',
                    onTap: () {
                      // TODO: 主题设置
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.download_outlined,
                    title: '数据导出',
                    onTap: () {
                      // TODO: 数据导出
                    },
                  ),
                  const SizedBox(height: 16),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: '关于',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Time Tracker',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 CaoChen',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.outline,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// TimePad 风格底部导航栏
class _TimePadBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _TimePadBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：时钟图标
          GestureDetector(
            onTap: () => onTap(0),
            child: Opacity(
              opacity: currentIndex == 0 ? 1.0 : 0.4,
              child: const Icon(
                Icons.access_time_outlined,
                size: 28,
                color: Color(0xFF000000),
              ),
            ),
          ),
          // 中间：添加按钮
          GestureDetector(
            onTap: () {
              // 弹出添加记录
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddRecordSheet(),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF070417),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          // 右侧：历史图标（空心时钟）
          GestureDetector(
            onTap: () => onTap(1),
            child: Opacity(
              opacity: currentIndex == 1 ? 1.0 : 0.4,
              child: const Icon(
                Icons.access_time_outlined,
                size: 28,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
