import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_signin/domain/models/attendance_record.dart';
import 'package:flutter_signin/domain/models/attendance_settings.dart';
import 'package:flutter_signin/domain/models/holiday_calendar.dart';
import 'package:flutter_signin/domain/use_cases/calculate_monthly_summary.dart';

void main() {
  const calculator = CalculateMonthlySummary();
  const settings = AttendanceSettings(excludedRanges: []);

  HolidayCalendarYear calendar(List<HolidayDate> dates) => HolidayCalendarYear(
    year: 2026,
    region: 'CN',
    dates: dates,
    source: 'test',
    importedAt: DateTime(2026),
  );

  AttendanceRecord record(int day, int startHour, int endHour) =>
      AttendanceRecord(
        date: DateTime(2026, 10, day),
        firstCheckIn: DateTime(2026, 10, day, startHour),
        lastCheckIn: DateTime(2026, 10, day, endHour),
      );

  test('averages all signed dates instead of all workdays', () {
    final summary = calculator(
      month: DateTime(2026, 10),
      now: DateTime(2026, 10, 5),
      records: [record(1, 8, 16), record(3, 8, 12)],
      settings: settings,
      calendar: calendar(const []),
    );

    expect(summary.checkedDayCount, 2);
    expect(summary.totalValidMinutes, 12 * 60);
    expect(summary.averageValidMinutes, 6 * 60);
  });

  test(
    'includes holiday sign-in without changing workday or missed counts',
    () {
      final summary = calculator(
        month: DateTime(2026, 10),
        now: DateTime(2026, 10, 5),
        records: [record(1, 8, 16), record(2, 8, 16)],
        settings: settings,
        calendar: calendar([
          HolidayDate(
            date: DateTime(2026, 10, 2),
            name: '国庆节',
            type: HolidayDateType.publicHoliday,
          ),
        ]),
      );

      expect(summary.workdayCount, 2);
      expect(summary.checkedDayCount, 2);
      expect(summary.missedDayCount, 0);
      expect(summary.averageValidMinutes, 8 * 60);
    },
  );

  test('does not count today without a record as missed', () {
    final summary = calculator(
      month: DateTime(2026, 10),
      now: DateTime(2026, 10, 5),
      records: const [],
      settings: settings,
      calendar: calendar(const []),
    );

    expect(summary.workdayCount, 3);
    expect(summary.missedDayCount, 2);
    expect(summary.averageValidMinutes, 0);
  });
}
