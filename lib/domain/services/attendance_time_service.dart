/// 处理本地墙上时间、UTC 时间和固定时区偏移之间的转换。
class AttendanceTimeService {
  const AttendanceTimeService._();

  static String formatOffset(Duration offset) {
    final minutes = offset.inMinutes;
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    return '$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:${(absolute % 60).toString().padLeft(2, '0')}';
  }

  static int parseOffsetMinutes(String value) {
    final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('时区格式不正确：$value');
    final minutes =
        int.parse(match.group(2)!) * 60 + int.parse(match.group(3)!);
    return match.group(1) == '-' ? -minutes : minutes;
  }

  static String formatOffsetMinutes(int minutes) =>
      formatOffset(Duration(minutes: minutes));

  static DateTime localWallTime(DateTime utc, int offsetMinutes) {
    // 先把 UTC 加上固定偏移，再构造没有时区标记的本地墙上时间。
    final shifted = utc.toUtc().add(Duration(minutes: offsetMinutes));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  static DateTime utcFromLocal(DateTime local, int offsetMinutes) =>
      DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
        local.microsecond,
      ).subtract(Duration(minutes: offsetMinutes));
}
