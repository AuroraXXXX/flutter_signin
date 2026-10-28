import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_signin/domain/models/attendance_record.dart';
import 'package:flutter_signin/domain/services/attendance_csv_service.dart';

void main() {
  const service = AttendanceCsvService();

  test('round trips seconds and escaped notes', () {
    final original = AttendanceRecord(
      date: DateTime(2026, 10, 27),
      firstCheckIn: DateTime(2026, 10, 27, 8, 30, 12),
      lastCheckIn: DateTime(2026, 10, 27, 18, 0, 15),
      note: '补签，备注 "已确认"\n第二行',
      attendanceSource: AttendanceSource.resign,
    );

    final result = service.decode(service.encode([original]));

    expect(result, hasLength(1));
    expect(result.single.firstCheckIn, original.firstCheckIn);
    expect(result.single.lastCheckIn, original.lastCheckIn);
    expect(result.single.note, original.note);
    expect(result.single.attendanceSource, AttendanceSource.resign);
    expect(service.encode([original]), contains('补签'));
  });

  test('rejects duplicate dates in one import', () {
    const csv = '''签到日期,首次签到时间,末次签到时间,备注,时区,签到来源,考勤类别
2026/10/27,08:00:00,17:00:00,,+08:00,正常签到,正常
2026/10/27,09:00:00,18:00:00,,+08:00,补签,正常
''';

    expect(() => service.decode(csv), throwsA(isA<AttendanceCsvException>()));
  });

  test('does not export or import absence rows', () {
    final csv = service.encode([
      AttendanceRecord(
        date: DateTime(2026, 10, 27),
        firstCheckIn: DateTime(2026, 10, 27, 8),
        lastCheckIn: DateTime(2026, 10, 27, 17),
      ),
    ]);

    expect(csv, isNot(contains('absent')));
    expect(
      () => service.decode('''签到日期,首次签到时间,末次签到时间,备注,时区,签到来源,考勤类别
 2026/10/28,,,,+08:00,,缺勤
'''),
      throwsA(isA<AttendanceCsvException>()),
    );
  });
}
