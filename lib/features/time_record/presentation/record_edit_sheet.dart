import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/datetime_picker.dart';
import '../../category/data/category_provider.dart';
import '../../statistics/data/statistics_provider.dart';

class RecordEditSheet extends ConsumerStatefulWidget {
  final TimeRecord record;
  const RecordEditSheet({super.key, required this.record});
  @override
  ConsumerState<RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends ConsumerState<RecordEditSheet> {
  late TextEditingController _nameController;
  late int? _selectedCategoryId;
  late String? _selectedIcon;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.record.name);
    _selectedCategoryId = widget.record.categoryId;
    _selectedIcon = widget.record.icon;
    _startTime = widget.record.startTime;
    _endTime = widget.record.endTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('编辑记录', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
                Pressable(
                  onTap: _confirmDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pressable(
                        onTap: () async {
                          final icon = await showIconPicker(context, selectedIcon: _selectedIcon);
                          if (icon != null) setState(() => _selectedIcon = icon);
                        },
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: IconDisplay(icon: _selectedIcon, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(fontSize: 16, color: isDark ? Colors.white : null),
                          decoration: InputDecoration(
                            hintText: '事件名称',
                            hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                            filled: true, fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('分类', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (categories) {
                      final categoryExists = _selectedCategoryId == null || categories.any((c) => c.id == _selectedCategoryId);
                      if (!categoryExists) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _selectedCategoryId = null));
                      }
                      return Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          _CategoryChip(name: '未分类', color: Colors.grey, isSelected: _selectedCategoryId == null, isDark: isDark, onTap: () => setState(() => _selectedCategoryId = null)),
                          ...categories.map((c) {
                            final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
                            return _CategoryChip(name: c.name, color: color, isSelected: _selectedCategoryId == c.id, isDark: isDark, onTap: () => setState(() => _selectedCategoryId = c.id));
                          }),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('加载失败'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _TimeCard(label: '开始', time: _startTime, isDark: isDark, onTap: () => _pickDateTime(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _TimeCard(label: '结束', time: _endTime, isDark: isDark, onTap: () => _pickDateTime(false))),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // 底部按钮
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1F2937) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('取消', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: _save,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('保存', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

  Future<void> _pickDateTime(bool isStart) async {
    final currentTime = isStart ? _startTime : _endTime;
    final result = await showDateTimePicker(context, initialDateTime: currentTime);
    if (result != null) setState(() => isStart ? _startTime = result : _endTime = result);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入事件名称')));
      return;
    }
    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('结束时间不能早于开始时间')));
      return;
    }
    final db = ref.read(databaseProvider);
    db.updateRecord(widget.record.copyWith(
      name: name,
      categoryId: Value(_selectedCategoryId),
      icon: Value(_selectedIcon),
      startTime: _startTime,
      endTime: Value(_endTime),
    ));
    ref.read(statisticsRefreshProvider.notifier).state++;
    Navigator.pop(context);
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1F2937) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text('确定删除这条记录吗？', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : null)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(height: 48, decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text('取消', style: GoogleFonts.poppins(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Pressable(
                    onTap: () {
                      final db = ref.read(databaseProvider);
                      db.deleteRecord(widget.record.id);
                      ref.read(statisticsRefreshProvider.notifier).state++;
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Container(height: 48, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text('删除', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _CategoryChip({required this.name, required this.color, required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(name, style: GoogleFonts.poppins(fontSize: 14, color: isSelected ? color : (isDark ? Colors.grey.shade300 : Colors.grey.shade700), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isDark;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.time, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : null)),
          ],
        ),
      ),
    );
  }
}

void showRecordEditSheet(BuildContext context, TimeRecord record) {
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => RecordEditSheet(record: record));
}
