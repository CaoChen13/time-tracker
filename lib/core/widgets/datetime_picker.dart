import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// 自定义日期时间选择器 Sheet
class DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime? minDateTime;
  final DateTime? maxDateTime;

  const DateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    this.minDateTime,
    this.maxDateTime,
  });

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late DateTime _selectedDateTime;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _generateDays();
    
    final dayIndex = _days.indexWhere((d) => 
      d.year == _selectedDateTime.year && 
      d.month == _selectedDateTime.month && 
      d.day == _selectedDateTime.day
    );
    
    _dayController = FixedExtentScrollController(initialItem: dayIndex >= 0 ? dayIndex : 30);
    _hourController = FixedExtentScrollController(initialItem: _selectedDateTime.hour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedDateTime.minute);
  }

  void _generateDays() {
    final now = DateTime.now();
    _days = List.generate(61, (i) => DateTime(now.year, now.month, now.day - 30 + i));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('选择时间', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
                Text(
                  _formatPreview(_selectedDateTime),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildWheelPicker(
                    controller: _dayController,
                    itemCount: _days.length,
                    isDark: isDark,
                    onChanged: (index) {
                      setState(() {
                        final day = _days[index];
                        _selectedDateTime = DateTime(day.year, day.month, day.day, _selectedDateTime.hour, _selectedDateTime.minute);
                      });
                    },
                    itemBuilder: (index) => _formatDay(_days[index]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildWheelPicker(
                    controller: _hourController,
                    itemCount: 24,
                    isDark: isDark,
                    onChanged: (index) {
                      setState(() {
                        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, index, _selectedDateTime.minute);
                      });
                    },
                    itemBuilder: (index) => index.toString().padLeft(2, '0'),
                  ),
                ),
                Text(':', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                Expanded(
                  flex: 2,
                  child: _buildWheelPicker(
                    controller: _minuteController,
                    itemCount: 60,
                    isDark: isDark,
                    onChanged: (index) {
                      setState(() {
                        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, _selectedDateTime.hour, index);
                      });
                    },
                    itemBuilder: (index) => index.toString().padLeft(2, '0'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
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
                    onTap: () => Navigator.pop(context, _selectedDateTime),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('确认', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required bool isDark,
    required ValueChanged<int> onChanged,
    required String Function(int) itemBuilder,
  }) {
    return Stack(
      children: [
        Center(
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          ),
        ),
        CupertinoPicker(
          scrollController: controller,
          itemExtent: 44,
          selectionOverlay: null,
          onSelectedItemChanged: onChanged,
          children: List.generate(itemCount, (index) {
            return Center(
              child: Text(itemBuilder(index), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF070417))),
            );
          }),
        ),
      ],
    );
  }

  String _formatDay(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}/${date.day} ${weekdays[date.weekday - 1]}';
  }

  String _formatPreview(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

Future<DateTime?> showDateTimePicker(
  BuildContext context, {
  required DateTime initialDateTime,
  DateTime? minDateTime,
  DateTime? maxDateTime,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DateTimePickerSheet(
      initialDateTime: initialDateTime,
      minDateTime: minDateTime,
      maxDateTime: maxDateTime,
    ),
  );
}
