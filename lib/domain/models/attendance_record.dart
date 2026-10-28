import '../services/attendance_time_service.dart';

/// 签到记录的来源：实时签到或人工补签。
enum AttendanceSource { normal, resign }

/// 根据签到时间计算出的考勤类别。
enum AttendanceStatus { normal, late, earlyLeave, missingCard }

/// 一天的签到记录。
class AttendanceRecord {
  AttendanceRecord({
    this.id,
    required this.date,
    required this.firstCheckIn,
    required this.lastCheckIn,
    this.note = '',
    this.attendanceSource = AttendanceSource.normal,
    String? timezone,
    this.firstCheckInUtc,
    this.lastCheckInUtc,
  }) : timezone =
           timezone ??
           AttendanceTimeService.formatOffset(DateTime.now().timeZoneOffset);

  final int? id;
  final DateTime date;
  final DateTime firstCheckIn;
  final DateTime lastCheckIn;
  final String note;
  final AttendanceSource attendanceSource;
  final String timezone;
  // 保留 UTC 时间用于计算真实时长，避免跨时区或夏令时造成误差。
  final DateTime? firstCheckInUtc;
  final DateTime? lastCheckInUtc;

  bool get isManual => attendanceSource == AttendanceSource.resign;

  AttendanceRecord copyWith({
    int? id,
    DateTime? date,
    DateTime? firstCheckIn,
    DateTime? lastCheckIn,
    String? note,
    AttendanceSource? attendanceSource,
    String? timezone,
    DateTime? firstCheckInUtc,
    DateTime? lastCheckInUtc,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      firstCheckIn: firstCheckIn ?? this.firstCheckIn,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      note: note ?? this.note,
      attendanceSource: attendanceSource ?? this.attendanceSource,
      timezone: timezone ?? this.timezone,
      firstCheckInUtc: firstCheckInUtc ?? this.firstCheckInUtc,
      lastCheckInUtc: lastCheckInUtc ?? this.lastCheckInUtc,
    );
  }
}
