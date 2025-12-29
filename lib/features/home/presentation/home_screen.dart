import 'package:flutter/material.dart';
import '../../time_record/presentation/record_tab.dart';
import '../../time_record/presentation/add_record_sheet.dart';

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
