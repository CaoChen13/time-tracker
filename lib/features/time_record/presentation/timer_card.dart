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
  int? _activeRecordId;
  DateTime? _activeStartTime;

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
          _startTimerIfNeeded(activeRecord);
          child = _ActiveTimerCard(
            key: const ValueKey('active'),
            record: activeRecord,
            elapsed: _elapsed,
            onStop: _stopTimer,
          );
        } else {
          _resetTimerState();
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

  void _startTimerIfNeeded(TimeRecord record) {
    if (_activeRecordId == record.id &&
        _activeStartTime == record.startTime) {
      return;
    }

    _activeRecordId = record.id;
    _activeStartTime = record.startTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(record.startTime);
        });
      }
    });

    setState(() {
      _elapsed = DateTime.now().difference(record.startTime);
    });
  }

  void _stopTimer() {
    ref.read(timeRecordServiceProvider).stopTimer();
    _timer?.cancel();
    _resetTimerState();
  }

  void _resetTimerState() {
    if (_activeRecordId == null) return;

    _timer?.cancel();
    setState(() {
      _activeRecordId = null;
      _activeStartTime = null;
      _elapsed = Duration.zero;
    });
  }
}

// 空闲状态 - TimePad 风格
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 114,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 输入框
          Expanded(
            child: TextField(
              controller: _nameController,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: '在做什么？',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF828282),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _startTimer(),
            ),
          ),
          // 分类选择 + 开始按钮
          Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...categories.take(3).map((c) {
                          final color = _parseColor(c.color);
                          final isSelected = _selectedCategoryId == c.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId =
                                      _selectedCategoryId == c.id ? null : c.id;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(0.15)
                                      : const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(6),
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
                                      c.name,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: isSelected
                                            ? color
                                            : const Color(0xFF828282),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Color(0xFF828282),
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
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  void _startTimer() async {
    final name = _nameController.text.trim();
    final taskName = name.isEmpty ? '未命名任务' : name;
    final categoryId = _selectedCategoryId;

    await ref.read(timeRecordServiceProvider).startTimer(
          name: taskName,
          categoryId: categoryId,
        );
    _nameController.clear();

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final activeRecord = await ref.read(activeRecordProvider.future);
    if (activeRecord != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimerDetailScreen(
            record: activeRecord,
            onStop: () async {
              await ref.read(timeRecordServiceProvider).stopTimer();
            },
          ),
        ),
      );
    }
  }
}

// 计时中状态 - 首页卡片样式（TimePad 风格）
class _ActiveTimerCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TimerDetailScreen(
              record: record,
              onStop: onStop,
            ),
          ),
        );
      },
      child: Container(
        height: 114,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 时间 - 左上
            Positioned(
              left: 0,
              top: 0,
              child: Text(
                _formatDuration(elapsed),
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF000000),
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
            // 项目名 + 紫色圆环 - 左下
            Positioned(
              left: 0,
              top: 44,
              child: Row(
                children: [
                  // 紫色空心圆环
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    record.name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            // 右箭头
            const Positioned(
              right: 0,
              top: -2,
              child: Icon(
                Icons.chevron_right,
                size: 24,
                color: Color(0xFF828282),
              ),
            ),
          ],
        ),
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

// 计时详情 - 全屏页面（TimePad 风格）
class TimerDetailScreen extends ConsumerStatefulWidget {
  final TimeRecord record;
  final VoidCallback onStop;

  const TimerDetailScreen({
    super.key,
    required this.record,
    required this.onStop,
  });

  @override
  ConsumerState<TimerDetailScreen> createState() => _TimerDetailScreenState();
}

class _TimerDetailScreenState extends ConsumerState<TimerDetailScreen> {
  late Duration _currentElapsed;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentElapsed = DateTime.now().difference(widget.record.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentElapsed = DateTime.now().difference(widget.record.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    
    String? categoryName;
    Color categoryColor = const Color(0xFFFF6B6B);
    
    categoriesAsync.whenData((categories) {
      if (widget.record.categoryId != null) {
        final category = categories.where((c) => c.id == widget.record.categoryId).firstOrNull;
        if (category != null) {
          categoryName = category.name;
          categoryColor = _parseColor(category.color);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.record.name,
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (categoryName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    categoryName!,
                    style: textTheme.labelMedium?.copyWith(
                      color: categoryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 紫色圆环 + 任务名
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.record.name,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 大号时间
              Text(
                _formatDuration(_currentElapsed),
                style: textTheme.displayMedium?.copyWith(
                  color: const Color(0xFF1F2937),
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [const FontFeature.tabularFigures()],
                  letterSpacing: -2,
                ),
              ),
              const Spacer(flex: 3),
              // Finish 按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(timeRecordServiceProvider).stopTimer();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: const Color(0xFF1F2937),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '完成',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Quit 按钮
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('放弃计时'),
                      content: const Text('确定要放弃这次计时吗？记录将不会保存。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(timeRecordServiceProvider).cancelTimer();
                            Navigator.pop(context);
                          },
                          child: const Text('放弃'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  '放弃',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF6B6B);
    }
  }
}
