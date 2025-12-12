import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/time_record_provider.dart';
import '../../category/data/category_provider.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../../core/database/database.dart';

class TimerCard extends ConsumerStatefulWidget {
  const TimerCard({super.key});

  @override
  ConsumerState<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends ConsumerState<TimerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRecordAsync = ref.watch(activeRecordProvider);

    return activeRecordAsync.when(
      data: (activeRecord) {
        Widget child;
        if (activeRecord != null) {
          _startTimer(activeRecord.startTime);
          child = _ActiveTimerCard(
            key: const ValueKey('active'),
            record: activeRecord,
            elapsed: _elapsed,
            onStop: _stopTimer,
          );
        } else {
          _timer?.cancel();
          child = const _IdleTimerCard(key: ValueKey('idle'));
        }
        // 卡片切换过渡动画
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      loading: () => const SizedBox(height: 200),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  void _startTimer(DateTime startTime) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(startTime);
        });
      }
    });
    _elapsed = DateTime.now().difference(startTime);
  }

  void _stopTimer() {
    ref.read(timeRecordServiceProvider).stopTimer();
    _timer?.cancel();
  }
}

// 空闲状态
class _IdleTimerCard extends ConsumerStatefulWidget {
  const _IdleTimerCard({super.key});

  @override
  ConsumerState<_IdleTimerCard> createState() => _IdleTimerCardState();
}

class _IdleTimerCardState extends ConsumerState<_IdleTimerCard> {
  final _nameController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // 输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '在做什么？',
                hintStyle: TextStyle(color: theme.colorScheme.outline),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _startTimer(),
            ),
          ),
          const SizedBox(height: 16),
          // 分类选择 + 开始按钮
          Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...categories.take(3).map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CategoryChip(
                                category: c,
                                isSelected: _selectedCategoryId == c.id,
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId =
                                        _selectedCategoryId == c.id ? null : c.id;
                                  });
                                },
                              ),
                            )),
                        // 添加分类按钮
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryListScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              const SizedBox(width: 12),
              // 开始按钮
              GestureDetector(
                onTap: _startTimer,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    // 允许空名称，默认「未命名任务」
    final name = _nameController.text.trim();

    ref.read(timeRecordServiceProvider).startTimer(
          name: name.isEmpty ? '未命名任务' : name,
          categoryId: _selectedCategoryId,
        );
    _nameController.clear();
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// 计时中状态 - 带动画
class _ActiveTimerCard extends StatefulWidget {
  final TimeRecord record;
  final Duration elapsed;
  final VoidCallback onStop;

  const _ActiveTimerCard({
    super.key,
    required this.record,
    required this.elapsed,
    required this.onStop,
  });

  @override
  State<_ActiveTimerCard> createState() => _ActiveTimerCardState();
}

class _ActiveTimerCardState extends State<_ActiveTimerCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pingController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    // Magic UI 风格: 柔和的光晕呼吸效果 (3s 周期，更慢更优雅)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // 绿点 ping 动画 (1.5s 周期)
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Aceternity 风格: 卡片微呼吸效果
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pingController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        // 微妙的阴影呼吸效果
        final breathe = Curves.easeInOut.transform(_breatheController.value);
        final shadowOpacity = 0.2 + breathe * 0.1;
        final shadowBlur = 20.0 + breathe * 10;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                Color.lerp(
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                  0.3,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(shadowOpacity),
                blurRadius: shadowBlur,
                offset: const Offset(0, 8),
                spreadRadius: breathe * 2,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: child,
        );
      },
      child: Stack(
        children: [
          // Magic UI 风格: 多层渐变光晕
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_glowController.value);
                  return Stack(
                    children: [
                      // 外层大光晕
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.12 + t * 0.08),
                              Colors.white.withOpacity(0.05 + t * 0.03),
                              Colors.white.withOpacity(0),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      // 内层亮点
                      Positioned(
                        top: 50,
                        left: 50,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.2 + t * 0.1),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // 内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 状态指示 - 绿点带 ping 动画
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 外圈光晕
                          AnimatedBuilder(
                            animation: _pingController,
                            builder: (context, child) {
                              final t = Curves.easeOutCubic
                                  .transform(_pingController.value);
                              return Container(
                                width: 8 + t * 16,
                                height: 8 + t * 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4ADE80)
                                      .withOpacity(0.6 * (1 - t)),
                                ),
                              );
                            },
                          ),
                          // 实心绿点 + 微光
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4ADE80).withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '正在记录',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 任务名称
                Text(
                  widget.record.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 计时器
                Text(
                  _formatDuration(widget.elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                // 停止按钮 - 带悬浮效果
                GestureDetector(
                  onTap: widget.onStop,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
