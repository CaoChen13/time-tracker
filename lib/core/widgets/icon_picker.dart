import 'package:flutter/material.dart';

/// 可选图标列表
const availableIcons = <String, IconData>{
  // 工作学习
  'work': Icons.work_outline,
  'laptop': Icons.laptop_mac,
  'desktop': Icons.desktop_mac_outlined,
  'school': Icons.school_outlined,
  'book': Icons.menu_book_outlined,
  'edit': Icons.edit_outlined,
  'code': Icons.code,
  
  // 生活
  'home': Icons.home_outlined,
  'bed': Icons.bed_outlined,
  'restaurant': Icons.restaurant_outlined,
  'coffee': Icons.coffee_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'local_grocery': Icons.local_grocery_store_outlined,
  
  // 运动健康
  'fitness': Icons.fitness_center_outlined,
  'directions_run': Icons.directions_run,
  'directions_bike': Icons.directions_bike,
  'pool': Icons.pool_outlined,
  'sports': Icons.sports_soccer,
  'favorite': Icons.favorite_outline,
  
  // 娱乐
  'movie': Icons.movie_outlined,
  'music': Icons.music_note_outlined,
  'games': Icons.sports_esports_outlined,
  'tv': Icons.tv_outlined,
  'headphones': Icons.headphones_outlined,
  'photo': Icons.photo_camera_outlined,
  
  // 社交
  'people': Icons.people_outline,
  'person': Icons.person_outline,
  'chat': Icons.chat_bubble_outline,
  'call': Icons.call_outlined,
  'email': Icons.email_outlined,
  
  // 交通
  'car': Icons.directions_car_outlined,
  'bus': Icons.directions_bus_outlined,
  'train': Icons.train_outlined,
  'flight': Icons.flight_outlined,
  'walk': Icons.directions_walk,
  
  // 其他
  'star': Icons.star_outline,
  'flag': Icons.flag_outlined,
  'bookmark': Icons.bookmark_outline,
  'lightbulb': Icons.lightbulb_outline,
  'build': Icons.build_outlined,
  'settings': Icons.settings_outlined,
  'time': Icons.access_time_outlined,
  'calendar': Icons.calendar_today_outlined,
};

/// 根据图标名称获取 IconData
IconData getIconByName(String? name) {
  if (name == null || name.isEmpty) return Icons.category_outlined;
  return availableIcons[name] ?? Icons.category_outlined;
}

/// 图标选择器对话框
class IconPickerDialog extends StatelessWidget {
  final String? selectedIcon;

  const IconPickerDialog({super.key, this.selectedIcon});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择图标'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: availableIcons.length,
          itemBuilder: (context, index) {
            final entry = availableIcons.entries.elementAt(index);
            final isSelected = entry.key == selectedIcon;
            
            return GestureDetector(
              onTap: () => Navigator.pop(context, entry.key),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  entry.value,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// 显示图标选择器
Future<String?> showIconPicker(BuildContext context, {String? selectedIcon}) {
  return showDialog<String>(
    context: context,
    builder: (context) => IconPickerDialog(selectedIcon: selectedIcon),
  );
}
