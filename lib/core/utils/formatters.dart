/// 时间格式化工具类
class DurationFormatter {
  DurationFormatter._();

  /// 格式化为 "1h 30m" 或 "30m 15s" 格式
  static String toHumanReadable(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// 格式化为 "01:30:15" 格式
  static String toTimer(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 格式化为 "01:30" 格式（时:分 或 分:秒）
  static String toShort(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化为完整格式 "1h 30m 15s"
  static String toFull(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// 日期时间格式化工具类
class DateTimeFormatter {
  DateTimeFormatter._();

  /// 格式化时间为 "09:30" 格式
  static String toTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化日期为 "2025-01-01" 格式
  static String toDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 格式化为 "2025-01-01 09:30" 格式
  static String toDateTime(DateTime dt) {
    return '${toDate(dt)} ${toTime(dt)}';
  }
}
