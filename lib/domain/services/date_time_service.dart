/// 应用内统一的日期、月份和时间格式化/比较工具。
class DateTimeService {
  const DateTimeService._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime monthOnly(DateTime value) =>
      DateTime(value.year, value.month);

  static bool isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static bool isSameMonth(DateTime first, DateTime second) =>
      first.year == second.year && first.month == second.month;

  static String dateKey(DateTime value, {String separator = '/'}) =>
      '${value.year.toString().padLeft(4, '0')}$separator'
      '${value.month.toString().padLeft(2, '0')}$separator'
      '${value.day.toString().padLeft(2, '0')}';

  static DateTime parseDateKey(String value) {
    final parts = value.split(RegExp(r'[-/]'));
    if (parts.length != 3) {
      throw const FormatException('日期必须是 yyyy/MM/dd 或 yyyy-MM-dd');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String timeKey(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';

  static DateTime combine(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length != 3) {
      throw const FormatException('时间必须是 HH:mm:ss');
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
