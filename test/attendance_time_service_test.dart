import 'package:flutter_signin/domain/services/attendance_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatOffset', () {
    test('formats positive, negative and zero offsets', () {
      expect(
        AttendanceTimeService.formatOffset(const Duration(minutes: 480)),
        '+08:00',
      );
      expect(
        AttendanceTimeService.formatOffset(const Duration(minutes: -330)),
        '-05:30',
      );
      expect(AttendanceTimeService.formatOffset(Duration.zero), '+00:00');
    });
  });

  group('parseOffsetMinutes', () {
    test('parses signed HH:mm offsets', () {
      expect(AttendanceTimeService.parseOffsetMinutes('+08:00'), 480);
      expect(AttendanceTimeService.parseOffsetMinutes('-05:30'), -330);
      expect(AttendanceTimeService.parseOffsetMinutes('+00:00'), 0);
    });

    test('treats Z and UTC as UTC', () {
      expect(AttendanceTimeService.parseOffsetMinutes('Z'), 0);
      expect(AttendanceTimeService.parseOffsetMinutes('UTC'), 0);
      expect(AttendanceTimeService.parseOffsetMinutes(''), 0);
    });

    test('rejects malformed offsets', () {
      for (final value in ['8', '08:60', 'abc', '+8:00x']) {
        expect(
          () => AttendanceTimeService.parseOffsetMinutes(value),
          throwsFormatException,
          reason: 'expected "$value" to be rejected',
        );
      }
    });
  });

  group('wall clock conversion', () {
    test('utcFromLocal returns a UTC instant shifted by the offset', () {
      final utc = AttendanceTimeService.utcFromLocal(
        DateTime(2026, 10, 27, 9, 5, 30),
        480,
      );
      expect(utc.isUtc, isTrue);
      expect(utc, DateTime.utc(2026, 10, 27, 1, 5, 30));
    });

    test('localWallTime inverts utcFromLocal', () {
      final wall = DateTime(2026, 10, 27, 9, 5, 30);
      final utc = AttendanceTimeService.utcFromLocal(wall, 480);
      expect(AttendanceTimeService.localWallTime(utc, 480), wall);
      expect(AttendanceTimeService.localWallTime(utc, 480).isUtc, isFalse);
    });

    test('negative offsets keep the intended instant', () {
      final utc = AttendanceTimeService.utcFromLocal(
        DateTime(2026, 10, 27, 9),
        -330,
      );
      expect(utc, DateTime.utc(2026, 10, 27, 14, 30));
      expect(
        AttendanceTimeService.localWallTime(utc, -330),
        DateTime(2026, 10, 27, 9),
      );
    });

    test('durations spanning midnight use the UTC instants', () {
      final first = AttendanceTimeService.utcFromLocal(
        DateTime(2026, 10, 27, 22),
        480,
      );
      final last = AttendanceTimeService.utcFromLocal(
        DateTime(2026, 10, 28, 6),
        480,
      );
      expect(last.difference(first), const Duration(hours: 8));
    });
  });
}
