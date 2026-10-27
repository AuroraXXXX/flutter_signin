/// Conversions between wall-clock times, fixed UTC offsets and UTC instants.
///
/// A record stores three views of the same moment:
///
/// * a local wall-clock time such as `2026-10-27 09:05:00`, used for display
///   and for the attendance windows,
/// * the device time zone at capture time, formatted like `+08:00`,
/// * the UTC instant, used to compute durations across DST or time zone
///   changes.
///
/// Wall-clock values are plain `DateTime`s whose fields carry the local time;
/// UTC values are `DateTime`s with [DateTime.isUtc] set to `true`.
class AttendanceTimeService {
  const AttendanceTimeService._();

  /// Formats [offset] as a `±HH:mm` string, for example `+08:00`.
  static String formatOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes < 0 ? '-' : '+';
    final absolute = totalMinutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final minutes = (absolute % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  /// Parses a `±HH:mm` offset into signed minutes, for example `+08:00` to 480.
  ///
  /// `Z`, `UTC` and an empty string are treated as UTC. A missing sign is
  /// treated as positive. Malformed input throws a [FormatException].
  static int parseOffsetMinutes(String offset) {
    final value = offset.trim();
    if (value.isEmpty || value == 'Z' || value.toUpperCase() == 'UTC') return 0;
    final match = RegExp(r'^([+-])?(\d{1,2}):?(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('时区必须是如 +08:00 的格式', offset);
    }
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    if (minutes >= 60) {
      throw FormatException('时区的分钟部分必须小于 60', offset);
    }
    return sign * (hours * 60 + minutes);
  }

  /// Converts [utc] to the wall-clock time observed at [offsetMinutes].
  ///
  /// The returned value is a local `DateTime` (not [DateTime.isUtc]) whose
  /// fields equal the wall clock in that zone.
  static DateTime localWallTime(DateTime utc, int offsetMinutes) {
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

  /// Converts a wall-clock time at [offsetMinutes] to its UTC instant.
  ///
  /// [local] is interpreted by its calendar fields only; an existing
  /// [DateTime.isUtc] flag or a different device time zone is ignored.
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
