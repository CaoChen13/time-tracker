import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/statistics_provider.dart';
import '../../category/data/category_provider.dart';
import '../../template/data/template_provider.dart';
import '../../time_record/presentation/record_edit_sheet.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';

enum StatsViewType { list, pie, bar }

class StatisticsTab extends ConsumerStatefulWidget {
  const StatisticsTab({super.key});

  @override
  ConsumerState<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<StatisticsTab> {
  DateTime _selectedDate = DateTime.now();
  StatsViewType _viewType = StatsViewType.list;
  DateRangeType _rangeType = DateRangeType.day;
  bool _isEditMode = false;
  Set<int> _selectedRecordIds = {};
  bool _showUntrackedTime = false;
  int? _selectedPieCategoryId; // 饼图选中的分类ID，null表示未选中

  @override
  Widget build(BuildContext context) {
    // 监听刷新通知，强制重新获取数据
    ref.listen<int>(statisticsRefreshProvider, (_, __) {
      final params = RangeParams(_selectedDate, _rangeType);
      ref.invalidate(recordsByRangeProvider(params));
      ref.invalidate(statsByRangeProvider(params));
      ref.invalidate(totalByRangeProvider(params));
    });

    final params = RangeParams(_selectedDate, _rangeType);
    final statsAsync = ref.watch(statsByRangeProvider(params));
    final totalAsync = ref.watch(totalByRangeProvider(params));
    final recordsAsync = ref.watch(recordsByRangeProvider(params));
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // 顶部标题栏
          _buildHeader(context, isDark),
          // 日期选择器
          _buildDateSelector(isDark),
          // 总时长卡片
          totalAsync.when(
            data: (total) => _buildTotalCard(total),
            loading: () => const SizedBox(height: 80),
            error: (e, _) => Text('错误: $e'),
          ),
          // 视图切换
          _buildViewToggle(isDark),
          // 内容区域
          Expanded(
            child: statsAsync.when(
              data: (stats) => categoriesAsync.when(
                data: (categories) => recordsAsync.when(
                  data: (records) => _buildContent(stats, categories, records, isDark),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('错误: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('错误: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
            ),
          ),
          // 编辑模式底部栏 - 带滑入动画
          AnimatedSlide(
            offset: _isEditMode ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isEditMode ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isEditMode ? _buildEditModeBar(isDark) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              // 编辑按钮
              Pressable(
                onTap: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                    if (!_isEditMode) {
                      _selectedRecordIds.clear();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEditMode 
                        ? AppColors.error.withOpacity(0.1) 
                        : (isDark ? const Color(0xFF374151) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isEditMode ? '完成' : '编辑',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isEditMode 
                          ? AppColors.error 
                          : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 更多菜单
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'export_csv') {
                    _exportData('csv');
                  } else if (value == 'export_html') {
                    _exportData('html');
                  } else if (value == 'toggle_untracked') {
                    setState(() {
                      _showUntrackedTime = !_showUntrackedTime;
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_untracked',
                    child: Row(
                      children: [
                        Icon(
                          _showUntrackedTime ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(_showUntrackedTime ? '隐藏未记录时段' : '显示未记录时段'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'export_csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        const Text('导出 CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_html',
                    child: Row(
                      children: [
                        Icon(Icons.code, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        const Text('导出 HTML'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Future<void> _exportData(String format) async {
    final params = RangeParams(_selectedDate, _rangeType);
    final records = await ref.read(recordsByRangeProvider(params).future);
    final categories = await ref.read(categoriesProvider.future);
    final categoryMap = {for (var c in categories) c.id: c};

    if (records.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有数据可导出')),
        );
      }
      return;
    }

    String content;
    String fileName;
    final dateStr = _getDateRangeString();

    if (format == 'csv') {
      fileName = 'time_records_$dateStr.csv';
      final buffer = StringBuffer();
      buffer.writeln('事件名称,分类,开始时间,结束时间,时长(分钟)');
      for (final record in records) {
        final category = record.categoryId != null ? categoryMap[record.categoryId] : null;
        final duration = record.endTime != null
            ? record.endTime!.difference(record.startTime).inMinutes
            : 0;
        buffer.writeln(
          '${record.name},${category?.name ?? "无分类"},${record.startTime},${record.endTime ?? "进行中"},$duration',
        );
      }
      content = buffer.toString();
    } else {
      fileName = 'time_records_$dateStr.html';
      final buffer = StringBuffer();
      buffer.writeln('<!DOCTYPE html>');
      buffer.writeln('<html><head><meta charset="UTF-8"><title>时间记录 - $dateStr</title>');
      buffer.writeln('<style>');
      buffer.writeln('body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; }');
      buffer.writeln('table { border-collapse: collapse; width: 100%; }');
      buffer.writeln('th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }');
      buffer.writeln('th { background-color: #8B5CF6; color: white; }');
      buffer.writeln('tr:nth-child(even) { background-color: #f9f9f9; }');
      buffer.writeln('.category { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 12px; }');
      buffer.writeln('</style></head><body>');
      buffer.writeln('<h1>时间记录 - $dateStr</h1>');
      buffer.writeln('<table><tr><th>事件名称</th><th>分类</th><th>开始时间</th><th>结束时间</th><th>时长</th></tr>');
      for (final record in records) {
        final category = record.categoryId != null ? categoryMap[record.categoryId] : null;
        final duration = record.endTime != null
            ? record.endTime!.difference(record.startTime)
            : Duration.zero;
        final durationStr = '${duration.inHours}小时${duration.inMinutes % 60}分钟';
        final categoryHtml = category != null
            ? '<span class="category" style="background-color: ${category.color}20; color: ${category.color};">${category.name}</span>'
            : '无分类';
        buffer.writeln(
          '<tr><td>${record.name}</td><td>$categoryHtml</td><td>${_formatDateTime(record.startTime)}</td><td>${record.endTime != null ? _formatDateTime(record.endTime!) : "进行中"}</td><td>$durationStr</td></tr>',
        );
      }
      buffer.writeln('</table></body></html>');
      content = buffer.toString();
    }

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('无法获取存储目录');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存到: ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  String _getDateRangeString() {
    switch (_rangeType) {
      case DateRangeType.day:
        return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      case DateRangeType.week:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.month}.${weekStart.day}-${weekEnd.month}.${weekEnd.day}';
      case DateRangeType.month:
        return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
      case DateRangeType.year:
        return '${_selectedDate.year}';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _deleteSelectedRecords() async {
    if (_selectedRecordIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedRecordIds.length} 条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      for (final id in _selectedRecordIds) {
        await db.deleteRecord(id);
      }
      // 刷新数据
      ref.invalidate(recordsByRangeProvider);
      ref.invalidate(statsByRangeProvider);
      ref.invalidate(totalByRangeProvider);
      setState(() {
        _selectedRecordIds.clear();
        _isEditMode = false;
      });
    }
  }

  Widget _buildEditModeBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 全选按钮
          Pressable(
            onTap: () async {
              final params = RangeParams(_selectedDate, _rangeType);
              final records = await ref.read(recordsByRangeProvider(params).future);
              setState(() {
                if (_selectedRecordIds.length == records.length) {
                  _selectedRecordIds.clear();
                } else {
                  _selectedRecordIds = records.map((r) => r.id).toSet();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '全选',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 已选数量
          Expanded(
            child: Text(
              '已选 ${_selectedRecordIds.length} 项',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          // 删除按钮
          Pressable(
            onTap: _selectedRecordIds.isEmpty ? null : _deleteSelectedRecords,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedRecordIds.isEmpty
                    ? (isDark ? const Color(0xFF374151) : Colors.grey.shade200)
                    : AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '删除',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedRecordIds.isEmpty
                      ? Colors.grey.shade400
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDateSelector(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // 范围类型选择
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: DateRangeType.values.map((type) {
                final isSelected = type == _rangeType;
                return Pressable(
                  onTap: () => setState(() => _rangeType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? const Color(0xFF1F2937) : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _getRangeTypeName(type),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          // 日期导航
          Row(
            children: [
              Pressable(
                onTap: () => _changeDate(-1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_left, size: 20, color: isDark ? Colors.grey.shade300 : null),
                ),
              ),
              Pressable(
                onTap: () => _showDatePicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _getDateLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                ),
              ),
              Pressable(
                onTap: () => _changeDate(1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.grey.shade300 : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRangeTypeName(DateRangeType type) {
    switch (type) {
      case DateRangeType.day:
        return '日';
      case DateRangeType.week:
        return '周';
      case DateRangeType.month:
        return '月';
      case DateRangeType.year:
        return '年';
    }
  }

  String _getDateLabel() {
    switch (_rangeType) {
      case DateRangeType.day:
        final now = DateTime.now();
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day) {
          return '今天';
        }
        return '${_selectedDate.month}月${_selectedDate.day}日';
      case DateRangeType.week:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.month}.${weekStart.day} - ${weekEnd.month}.${weekEnd.day}';
      case DateRangeType.month:
        return '${_selectedDate.year}年${_selectedDate.month}月';
      case DateRangeType.year:
        return '${_selectedDate.year}年';
    }
  }

  void _changeDate(int delta) {
    setState(() {
      switch (_rangeType) {
        case DateRangeType.day:
          _selectedDate = _selectedDate.add(Duration(days: delta));
          break;
        case DateRangeType.week:
          _selectedDate = _selectedDate.add(Duration(days: delta * 7));
          break;
        case DateRangeType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + delta,
            1,
          );
          break;
        case DateRangeType.year:
          _selectedDate = DateTime(_selectedDate.year + delta, 1, 1);
          break;
      }
    });
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }


  Widget _buildTotalCard(Duration total) {
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '总计时长',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$hours',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    ' 小时 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$minutes',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    ' 分钟',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildViewButton(StatsViewType.list, Icons.list, '列表', isDark),
          const SizedBox(width: 8),
          _buildViewButton(StatsViewType.pie, Icons.pie_chart, '饼图', isDark),
          const SizedBox(width: 8),
          _buildViewButton(StatsViewType.bar, Icons.bar_chart, '柱状', isDark),
        ],
      ),
    );
  }

  Widget _buildViewButton(StatsViewType type, IconData icon, String label, bool isDark) {
    final isSelected = _viewType == type;
    return Pressable(
      onTap: () => setState(() => _viewType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? const Color(0xFF374151) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primary, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildContent(
    Map<int?, Duration> stats,
    List<Category> categories,
    List<TimeRecord> records,
    bool isDark,
  ) {
    switch (_viewType) {
      case StatsViewType.list:
        return _buildListView(stats, categories, records, isDark);
      case StatsViewType.pie:
        return _buildPieChart(stats, categories, isDark);
      case StatsViewType.bar:
        return _buildBarChart(stats, categories, isDark);
    }
  }

  Widget _buildListView(
    Map<int?, Duration> stats,
    List<Category> categories,
    List<TimeRecord> records,
    bool isDark,
  ) {
    if (records.isEmpty && !_showUntrackedTime) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无记录',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final categoryMap = {for (var c in categories) c.id: c};
    final templatesAsync = ref.watch(templatesProvider);

    // 构建显示列表（包含记录和未记录时段）
    List<dynamic> displayItems = [];

    if (_showUntrackedTime && records.isNotEmpty) {
      // 计算未记录时段
      final sortedRecords = List<TimeRecord>.from(records)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // 获取当天的开始和结束时间
      DateTime dayStart;
      DateTime dayEnd;

      switch (_rangeType) {
        case DateRangeType.day:
          dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
          dayEnd = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
          break;
        default:
          // 对于周/月/年视图，使用第一条和最后一条记录的日期范围
          dayStart = DateTime(
            sortedRecords.first.startTime.year,
            sortedRecords.first.startTime.month,
            sortedRecords.first.startTime.day,
            0,
            0,
          );
          final lastRecord = sortedRecords.last;
          final lastEnd = lastRecord.endTime ?? DateTime.now();
          dayEnd = DateTime(lastEnd.year, lastEnd.month, lastEnd.day, 23, 59, 59);
          break;
      }

      // 只在日视图显示未记录时段
      if (_rangeType == DateRangeType.day) {
        DateTime currentTime = dayStart;

        for (final record in sortedRecords) {
          // 如果当前时间早于记录开始时间，添加未记录时段
          if (currentTime.isBefore(record.startTime)) {
            final gap = record.startTime.difference(currentTime);
            if (gap.inMinutes >= 1) {
              displayItems.add(_UntrackedGap(start: currentTime, end: record.startTime));
            }
          }
          displayItems.add(record);
          // 更新当前时间为记录结束时间
          currentTime = record.endTime ?? DateTime.now();
        }

        // 检查最后一条记录后是否有未记录时段（到当前时间或当天结束）
        final now = DateTime.now();
        final effectiveEnd = now.isBefore(dayEnd) ? now : dayEnd;
        if (currentTime.isBefore(effectiveEnd)) {
          final gap = effectiveEnd.difference(currentTime);
          if (gap.inMinutes >= 1) {
            displayItems.add(_UntrackedGap(start: currentTime, end: effectiveEnd));
          }
        }
      } else {
        displayItems = List.from(records);
      }
    } else {
      displayItems = List.from(records);
    }

    // 按时间倒序排列
    displayItems.sort((a, b) {
      final aTime = a is TimeRecord ? a.startTime : (a as _UntrackedGap).start;
      final bTime = b is TimeRecord ? b.startTime : (b as _UntrackedGap).start;
      return bTime.compareTo(aTime);
    });

    return templatesAsync.when(
      data: (templates) {
        final templateMap = {for (var t in templates) t.name: t};

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];

            if (item is _UntrackedGap) {
              return _buildUntrackedGapCard(item, isDark);
            }

            final record = item as TimeRecord;
            final category = record.categoryId != null ? categoryMap[record.categoryId] : null;
            final template = templateMap[record.name];
            final duration = record.endTime != null
                ? record.endTime!.difference(record.startTime)
                : DateTime.now().difference(record.startTime);

            return _RecordCard(
              record: record,
              category: category,
              template: template,
              duration: duration,
              isEditMode: _isEditMode,
              isSelected: _selectedRecordIds.contains(record.id),
              isDark: isDark,
              onTap: () {
                if (_isEditMode) {
                  setState(() {
                    if (_selectedRecordIds.contains(record.id)) {
                      _selectedRecordIds.remove(record.id);
                    } else {
                      _selectedRecordIds.add(record.id);
                    }
                  });
                } else {
                  showRecordEditSheet(context, record);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }


  Widget _buildPieChart(Map<int?, Duration> stats, List<Category> categories, bool isDark) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('暂无数据', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
          ],
        ),
      );
    }

    final categoryMap = {for (var c in categories) c.id: c};
    final total = stats.values.fold<Duration>(Duration.zero, (a, b) => a + b);
    final totalMinutes = total.inMinutes;

    // 转换为列表以便排序和遍历
    final statsList = stats.entries.toList()
      ..sort((a, b) => b.value.inMinutes.compareTo(a.value.inMinutes));

    // 获取选中分类的信息
    String centerTitle = 'Time tracked';
    String centerValue = DurationFormatter.toHumanReadable(total);
    if (_selectedPieCategoryId != null || _selectedPieCategoryId == 0) {
      // 检查是否选中了"未分类"（categoryId 为 null，用特殊标记 -1 表示）
      final isUncategorized = _selectedPieCategoryId == -1;
      if (isUncategorized && stats.containsKey(null)) {
        centerTitle = '未分类';
        centerValue = DurationFormatter.toHumanReadable(stats[null]!);
      } else if (!isUncategorized) {
        final selectedCategory = categoryMap[_selectedPieCategoryId];
        final selectedDuration = stats[_selectedPieCategoryId];
        if (selectedCategory != null && selectedDuration != null) {
          centerTitle = selectedCategory.name;
          centerValue = DurationFormatter.toHumanReadable(selectedDuration);
        }
      }
    }

    return Column(
      children: [
        // 饼图
        SizedBox(
          height: 280,
          child: GestureDetector(
            onTap: () {
              // 点击空白区域取消选中
              setState(() => _selectedPieCategoryId = null);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                          final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                          if (touchedIndex >= 0 && touchedIndex < statsList.length) {
                            final entry = statsList[touchedIndex];
                            setState(() {
                              // 用 -1 表示"未分类"
                              final newId = entry.key ?? -1;
                              _selectedPieCategoryId = _selectedPieCategoryId == newId ? null : newId;
                            });
                          }
                        }
                      },
                    ),
                    sections: statsList.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      final category = entry.key != null ? categoryMap[entry.key] : null;
                      final color = category != null
                          ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                          : Colors.grey;
                      final percentage = totalMinutes > 0 ? (entry.value.inMinutes / totalMinutes * 100) : 0.0;
                      
                      // 判断是否选中
                      final isSelected = _selectedPieCategoryId == (entry.key ?? -1);
                      final baseRadius = 80.0;
                      final radius = isSelected ? baseRadius + 12 : baseRadius;

                      // 扇区标签：占比 ≥5% 时显示百分比 + 分类名
                      String title = '';
                      if (percentage >= 5) {
                        final name = category?.name ?? '未分类';
                        title = '${percentage.toStringAsFixed(0)}%\n$name';
                      }

                      return PieChartSectionData(
                        value: entry.value.inMinutes.toDouble(),
                        color: color,
                        radius: radius,
                        title: title,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        titlePositionPercentageOffset: 0.55,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                  ),
                ),
                // 中心文字
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      centerValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 图例
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: statsList.length,
            itemBuilder: (context, index) {
              final entry = statsList[index];
              final category = entry.key != null ? categoryMap[entry.key] : null;
              final color = category != null
                  ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                  : Colors.grey;
              final isSelected = _selectedPieCategoryId == (entry.key ?? -1);

              return Pressable(
                onTap: () {
                  setState(() {
                    final newId = entry.key ?? -1;
                    _selectedPieCategoryId = _selectedPieCategoryId == newId ? null : newId;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: color, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category?.name ?? '未分类',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? color : (isDark ? Colors.white : AppColors.textPrimary),
                          ),
                        ),
                      ),
                      Text(
                        DurationFormatter.toHumanReadable(entry.value),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<int?, Duration> stats, List<Category> categories, bool isDark) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('暂无数据', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
          ],
        ),
      );
    }

    final categoryMap = {for (var c in categories) c.id: c};
    
    // 转换为列表以便排序和遍历
    final statsList = stats.entries.toList()
      ..sort((a, b) => b.value.inMinutes.compareTo(a.value.inMinutes));
    
    final maxMinutes = statsList.first.value.inMinutes;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final entry = statsList[index];
        final category = entry.key != null ? categoryMap[entry.key] : null;
        final color = category != null
            ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
            : Colors.grey;
        final ratio = maxMinutes > 0 ? entry.value.inMinutes / maxMinutes : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category?.name ?? '未分类',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : null),
                  ),
                  Text(
                    '${(entry.value.inMinutes / 60).toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildUntrackedGapCard(_UntrackedGap gap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          // 左侧：灰色虚线圆圈
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Icon(
              Icons.hourglass_empty,
              size: 20,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          // 中间：未记录 + 时间段
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateTimeFormatter.toTime(gap.start)} - ${DateTimeFormatter.toTime(gap.end)}',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
              ],
            ),
          ),
          // 右侧：时长
          Text(
            DurationFormatter.toShort(gap.duration),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// 未记录时段数据类
class _UntrackedGap {
  final DateTime start;
  final DateTime end;

  _UntrackedGap({required this.start, required this.end});

  Duration get duration => end.difference(start);
}

// 记录卡片组件 - 支持左滑删除
class _RecordCard extends ConsumerStatefulWidget {
  final TimeRecord record;
  final Category? category;
  final EventTemplate? template;
  final Duration duration;
  final bool isEditMode;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RecordCard({
    required this.record,
    this.category,
    this.template,
    required this.duration,
    required this.isEditMode,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  ConsumerState<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends ConsumerState<_RecordCard> {
  double _dragExtent = 0;
  static const double _actionWidth = 80;

  @override
  void didUpdateWidget(covariant _RecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 进入编辑模式时重置滑动位置
    if (widget.isEditMode && !oldWidget.isEditMode) {
      _dragExtent = 0;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isEditMode) return; // 编辑模式下禁用滑动
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-_actionWidth, 0); // 只允许左滑
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isEditMode) return;
    setState(() {
      _dragExtent = _dragExtent < -_actionWidth / 2 ? -_actionWidth : 0;
    });
  }

  void _resetPosition() {
    setState(() => _dragExtent = 0);
  }

  Future<void> _handleDelete() async {
    final db = ref.read(databaseProvider);
    await db.deleteRecord(widget.record.id);
    // 刷新统计数据
    ref.invalidate(recordsByRangeProvider);
    ref.invalidate(statsByRangeProvider);
    ref.invalidate(totalByRangeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category != null
        ? Color(int.parse(widget.category!.color.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    // 编辑模式下强制重置位置
    final effectiveDragExtent = widget.isEditMode ? 0.0 : _dragExtent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 76,
        child: Stack(
          children: [
            // 右侧删除按钮背景 - 编辑模式下隐藏
            if (!widget.isEditMode)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: _actionWidth,
                child: GestureDetector(
                  onTap: _handleDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white, size: 20),
                        SizedBox(height: 2),
                        Text('删除', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            // 前景卡片
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              left: effectiveDragExtent,
              right: -effectiveDragExtent,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: widget.isEditMode ? null : _handleDragUpdate,
                onHorizontalDragEnd: widget.isEditMode ? null : _handleDragEnd,
                onTap: () {
                  if (effectiveDragExtent != 0) {
                    _resetPosition();
                  } else {
                    widget.onTap();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? AppColors.primary.withOpacity(0.05) 
                        : (widget.isDark ? const Color(0xFF1F2937) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(widget.isSelected ? 0.08 : 0.03),
                        blurRadius: widget.isSelected ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 编辑模式下的选择框
                      if (widget.isEditMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: widget.isSelected ? AppColors.primary : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: widget.isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      // 图标
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: IconDisplay(
                            icon: widget.template?.icon ?? widget.record.icon,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.record.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark ? Colors.white : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (widget.category != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.category!.name,
                                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    '${DateTimeFormatter.toTime(widget.record.startTime)} - ${widget.record.endTime != null ? DateTimeFormatter.toTime(widget.record.endTime!) : "进行中"}',
                                    style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 时长
                      Text(
                        DurationFormatter.toHumanReadable(widget.duration),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
