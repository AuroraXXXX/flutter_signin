import '../services/attendance_time_service.dart';

enum AttendanceSource { normal, resign }

enum AttendanceStatus { normal, late, earlyLeave, missingCard }

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
