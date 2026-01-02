import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../template/presentation/template_list_screen.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../category/presentation/quick_category_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnimations;

  final _menuItems = [
    {'icon': Icons.folder_outlined, 'title': '分类管理', 'route': 'category'},
    {'icon': Icons.sell_outlined, 'title': '快捷分类', 'route': 'quickCategory'},
    {'icon': Icons.bookmark_outline, 'title': '事件库', 'route': 'template'},
    {'icon': Icons.settings_outlined, 'title': '设置', 'route': 'settings'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 为每个菜单项创建错开的动画
    _itemAnimations = List.generate(_menuItems.length, (index) {
      final start = index * 0.15;
      final end = start + 0.5;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMenuTap(String route) {
    switch (route) {
      case 'category':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CategoryListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'quickCategory':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const QuickCategoryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'template':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const TemplateListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '我的',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF070417),
                ),
              ),
            ),
            // 菜单列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return AnimatedBuilder(
                    animation: _itemAnimations[index],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
                        child: Opacity(
                          opacity: _itemAnimations[index].value,
                          child: child,
                        ),
                      );
                    },
                    child: _MenuItem(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      onTap: () => _handleMenuTap(item['route'] as String),
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark 
        ? (_isPressed ? const Color(0xFF374151) : const Color(0xFF1F2937))
        : (_isPressed ? Colors.grey.shade50 : Colors.white);
    final shadowColor = widget.isDark 
        ? Colors.black.withOpacity(_isPressed ? 0.1 : 0.2)
        : Colors.black.withOpacity(_isPressed ? 0.02 : 0.04);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: _isPressed ? 4 : 8,
              offset: Offset(0, _isPressed ? 1 : 2),
            ),
          ],
        ),
        child: ListTile(
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(_isPressed ? 0.2 : (widget.isDark ? 0.15 : 0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white : null,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isPressed ? 0.05 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              Icons.chevron_right,
              color: widget.isDark ? Colors.grey.shade500 : const Color(0xFF828282),
            ),
          ),
        ),
      ),
    );
  }
}
