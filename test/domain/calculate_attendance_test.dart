import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_signin/domain/models/attendance_record.dart';
import 'package:flutter_signin/domain/models/attendance_settings.dart';
import 'package:flutter_signin/domain/use_cases/calculate_attendance.dart';

void main() {
  const calculator = CalculateAttendance();
  const settings = AttendanceSettings();

  test('keeps valid work duration precise to seconds', () {
    final record = AttendanceRecord(
      date: DateTime(2026, 10, 27),
      firstCheckIn: DateTime(2026, 10, 27, 8, 30, 12),
      lastCheckIn: DateTime(2026, 10, 27, 18, 0, 15),
    );

    final evaluation = calculator(record, settings);

    expect(evaluation.excludedDuration, const Duration(minutes: 60));
    expect(
      evaluation.validDuration,
      const Duration(hours: 8, minutes: 30, seconds: 3),
    );
  });

  test('uses seconds when comparing minimum effective duration', () {
    final record = AttendanceRecord(
      date: DateTime(2026, 10, 27),
      firstCheckIn: DateTime(2026, 10, 27, 8),
      lastCheckIn: DateTime(2026, 10, 27, 17),
    );

    final evaluation = calculator(record, settings);

    expect(evaluation.validDuration, const Duration(hours: 8));
    expect(evaluation.isValid, isTrue);
  });

  test('does not report errors for a first check-in', () {
    final record = AttendanceRecord(
      date: DateTime(2026, 10, 27),
      firstCheckIn: DateTime(2026, 10, 27, 8, 30),
      lastCheckIn: DateTime(2026, 10, 27, 8, 30),
    );

    final evaluation = calculator(record, settings);

    expect(evaluation.isInProgress, isTrue);
    expect(evaluation.issues, isEmpty);
  });
}
