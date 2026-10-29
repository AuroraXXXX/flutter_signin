import '../../domain/models/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/attendance_time_service.dart';
import '../../domain/services/date_time_service.dart';
import '../services/attendance_database.dart';

/// 使用 SQLite 保存签到记录的 Repository 实现。
class SqliteAttendanceRepository implements AttendanceRepository {
  const SqliteAttendanceRepository(this._database);

  final AttendanceDatabase _database;

  @override
  Future<List<AttendanceRecord>> getAll() async {
    final rows = await _database.database.query(
      'attendance_records',
      orderBy: 'date_key DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<AttendanceRecord> save(AttendanceRecord record) async {
    final now = DateTime.now().toIso8601String();
    // 数据库同时保存本地显示时间和 UTC 时间：前者用于展示，后者用于计算时长。
    final values = _values(record, now);

    if (record.id == null) {
      values['created_at'] = now;
      final id = await _database.database.insert('attendance_records', values);
      return record.copyWith(id: id);
    }

    await _database.database.update(
      'attendance_records',
      values,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
  }

  @override
  Future<void> saveAll(
    List<AttendanceRecord> records, {
    required bool overwrite,
  }) async {
    // 批量导入放在事务中，确保整批数据不会只保存一部分。
    await _database.database.transaction((transaction) async {
      for (final record in records) {
        final existing = await transaction.query(
          'attendance_records',
          columns: ['id'],
          where: 'date_key = ?',
          whereArgs: [DateTimeService.dateKey(record.date)],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          // overwrite=false 用于“跳过已有”，避免导入覆盖用户现有记录。
          if (!overwrite) continue;
          await transaction.update(
            'attendance_records',
            _values(record, DateTime.now().toIso8601String()),
            where: 'date_key = ?',
            whereArgs: [DateTimeService.dateKey(record.date)],
          );
        } else {
          final now = DateTime.now().toIso8601String();
          final values = _values(record, now)..['created_at'] = now;
          await transaction.insert('attendance_records', values);
        }
      }
    });
  }

  @override
  Future<void> delete(int id) async {
    await _database.database.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  AttendanceRecord _fromMap(Map<String, Object?> map) {
    final date = _parseDate(map['date_key']! as String);
    final firstCheckIn = _combine(date, map['first_check_in_time']! as String);
    final lastCheckIn = _combine(date, map['last_check_in_time']! as String);
    return AttendanceRecord(
      id: map['id']! as int,
      date: date,
      firstCheckIn: firstCheckIn,
      lastCheckIn: lastCheckIn,
      note: map['note']! as String,
      attendanceSource: map['attendance_source'] == 'resign'
          ? AttendanceSource.resign
          : AttendanceSource.normal,
      timezone: map['timezone']! as String,
      firstCheckInUtc: DateTime.parse(map['first_check_in_utc']! as String),
      lastCheckInUtc: DateTime.parse(map['last_check_in_utc']! as String),
    );
  }

  Map<String, Object?> _values(AttendanceRecord record, String now) => {
    'date_key': DateTimeService.dateKey(record.date),
    'first_check_in_time': DateTimeService.timeKey(record.firstCheckIn),
    'last_check_in_time': DateTimeService.timeKey(record.lastCheckIn),
    'first_check_in_utc':
        (record.firstCheckInUtc ??
                AttendanceTimeService.utcFromLocal(
                  record.firstCheckIn,
                  AttendanceTimeService.parseOffsetMinutes(record.timezone),
                ))
            .toIso8601String(),
    'last_check_in_utc':
        (record.lastCheckInUtc ??
                AttendanceTimeService.utcFromLocal(
                  record.lastCheckIn,
                  AttendanceTimeService.parseOffsetMinutes(record.timezone),
                ))
            .toIso8601String(),
    'note': record.note,
    'timezone': record.timezone,
    'timezone_offset_minutes': AttendanceTimeService.parseOffsetMinutes(
      record.timezone,
    ),
    'attendance_source': record.attendanceSource.name,
    'updated_at': now,
  };

  DateTime _parseDate(String value) {
    return DateTimeService.parseDateKey(value);
  }

  DateTime _combine(DateTime date, String value) {
    return DateTimeService.combine(date, value);
  }
}
