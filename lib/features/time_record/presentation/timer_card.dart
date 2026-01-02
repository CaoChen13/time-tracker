import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/time_record_provider.dart';
import '../../category/data/category_provider.dart';
import '../../category/presentation/category_edit_sheet.dart';
import '../../statistics/data/statistics_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/pressable.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeRecord = ref.read(activeRecordProvider).valueOrNull;
      if (activeRecord != null && activeRecord.source == 'timerCard') {
        _startTimer(activeRecord);
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
    ref.listen<AsyncValue<TimeRecord?>>(activeRecordProvider, (previous, next) {
      final prevRecord = previous?.valueOrNull;
      final nextRecord = next.valueOrNull;
      
      if (nextRecord != null && nextRecord.source == 'timerCard' &&
          (prevRecord?.id != nextRecord.id || prevRecord?.startTime != nextRecord.startTime)) {
        _startTimer(nextRecord);
      } else if ((nextRecord == null || nextRecord.source != 'timerCard') && prevRecord?.source == 'timerCard') {
        _resetTimerState();
      }
    });

    final activeRecordAsync = ref.watch(activeRecordProvider);

    return activeRecordAsync.when(
      data: (activeRecord) {
        // 只有 timerCard 来源的计时才显示计时中状态
        if (activeRecord != null && activeRecord.source == 'timerCard') {
          return _ActiveTimerCard(
            key: const ValueKey('active'),
            record: activeRecord,
            elapsed: _elapsed,
            onStop: _stopTimer,
          );
        }
        return const _IdleTimerCard(key: ValueKey('idle'));
      },
      loading: () => const SizedBox(height: 160),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  void _startTimer(TimeRecord record) {
    if (_activeRecordId == record.id && _activeStartTime == record.startTime) return;

    _activeRecordId = record.id;
    _activeStartTime = record.startTime;
    _timer?.cancel();
    
    _elapsed = DateTime.now().difference(record.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(record.startTime));
      }
    });
    if (mounted) setState(() {});
  }

  void _stopTimer() {
    ref.read(timeRecordServiceProvider).stopTimer();
    // 触发统计页面刷新
    ref.read(statisticsRefreshProvider.notifier).state++;
    _timer?.cancel();
    _resetTimerState();
  }

  void _resetTimerState() {
    if (_activeRecordId == null) return;
    _timer?.cancel();
    _activeRecordId = null;
    _activeStartTime = null;
    _elapsed = Duration.zero;
    if (mounted) setState(() {});
  }
}


// 计时中状态卡片
class _ActiveTimerCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '正在进行',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record.name,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 计时显示
              Expanded(
                child: Text(
                  '$hours:$minutes:$seconds',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              // 停止按钮
              _AnimatedButton(
                onTap: onStop,
                color: const Color(0xFFF43F5E),
                icon: Icons.stop_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 空闲状态卡片
class _IdleTimerCard extends ConsumerStatefulWidget {
  const _IdleTimerCard({super.key});

  @override
  ConsumerState<_IdleTimerCard> createState() => _IdleTimerCardState();
}

class _IdleTimerCardState extends ConsumerState<_IdleTimerCard> {
  final _nameController = TextEditingController();
  int? _selectedCategoryId;
  bool _isPlayPressed = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(timerCardCategoriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 监听分类变化，检查当前选中的分类是否还在列表中
    ref.listen<AsyncValue<List<Category>>>(timerCardCategoriesProvider, (previous, next) {
      final categories = next.valueOrNull ?? [];
      if (_selectedCategoryId != null) {
        final stillExists = categories.any((c) => c.id == _selectedCategoryId);
        if (!stillExists) {
          // 选中的分类已被移除，重置为默认分类
          final defaultCat = categories.where((c) => c.isDefaultForTimerCard).firstOrNull;
          setState(() => _selectedCategoryId = defaultCat?.id);
        }
      }
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前任务',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF828282),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
            decoration: InputDecoration(
              hintText: '在做什么？',
              hintStyle: textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade600 : const Color(0xFFBDBDBD),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onSubmitted: (_) => _startTimer(),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) {
              // 默认选中默认分类
              if (_selectedCategoryId == null && categories.isNotEmpty) {
                final defaultCat = categories.where((c) => c.isDefaultForTimerCard).firstOrNull;
                if (defaultCat != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedCategoryId == null) {
                      setState(() => _selectedCategoryId = defaultCat.id);
                    }
                  });
                }
              }
              return Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((c) => _buildCategoryChip(c, textTheme, isDark)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isPlayPressed = true),
                    onTapUp: (_) {
                      setState(() => _isPlayPressed = false);
                      _startTimer();
                    },
                    onTapCancel: () => setState(() => _isPlayPressed = false),
                    child: AnimatedScale(
                      scale: _isPlayPressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _isPlayPressed 
                              ? AppColors.primary.withOpacity(0.8) 
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(_isPlayPressed ? 0.2 : 0.3),
                              blurRadius: _isPlayPressed ? 8 : 12,
                              offset: Offset(0, _isPlayPressed ? 2 : 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(height: 52),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category c, TextTheme textTheme, bool isDark) {
    final color = _parseColor(c.color);
    final isSelected = _selectedCategoryId == c.id;
    final unselectedBg = isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F7);
    final unselectedColor = isDark ? Colors.grey.shade400 : const Color(0xFF828282);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: () => setState(() => _selectedCategoryId = _selectedCategoryId == c.id ? null : c.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(isDark ? 0.25 : 0.15) : unselectedBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: 14, color: isSelected ? color : unselectedColor),
              const SizedBox(width: 6),
              Text(c.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? color : unselectedColor)),
            ],
          ),
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

  Future<void> _startTimer() async {
    final name = _nameController.text.trim();
    final taskName = name.isEmpty ? '未命名任务' : name;

    await ref.read(timeRecordServiceProvider).startTimer(
      name: taskName,
      categoryId: _selectedCategoryId,
      source: 'timerCard',
    );

    if (_selectedCategoryId != null) {
      await ref.read(categoryServiceProvider).incrementUsage(_selectedCategoryId!);
    }
    _nameController.clear();
  }
}


// 带动画的圆形按钮
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;

  const _AnimatedButton({
    required this.onTap,
    required this.color,
    required this.icon,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _isPressed ? widget.color.withOpacity(0.8) : widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isPressed ? 0.2 : 0.3),
                blurRadius: _isPressed ? 8 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
