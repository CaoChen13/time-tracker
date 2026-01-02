import 'package:flutter/material.dart';
import '../../time_record/presentation/record_tab.dart';
import '../../statistics/presentation/statistics_tab.dart';
import '../../profile/presentation/profile_tab.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';

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
          StatisticsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
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

// 底部导航栏
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 计时
          _NavItem(
            icon: Icons.access_time_outlined,
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            isDark: isDark,
          ),
          // 统计
          _NavItem(
            icon: Icons.pie_chart_outline,
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            isDark: isDark,
          ),
          // 我的
          _NavItem(
            icon: Icons.person_outline,
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scaleFactor: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.4,
          child: Icon(
            icon,
            size: 28,
            color: isSelected 
                ? AppColors.primary 
                : (isDark ? Colors.white : const Color(0xFF000000)),
          ),
        ),
      ),
    );
  }
}
