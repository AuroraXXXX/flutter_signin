import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/services/attendance_time_service.dart';
import 'database_factory.dart';

class AttendanceDatabase {
  AttendanceDatabase._(this.database);

  final Database database;

  static Future<AttendanceDatabase> open({String? path}) async {
    final factory = createDatabaseFactory();
    final databasePath =
        path ?? p.join(await factory.getDatabasesPath(), 'attendance.db');
    final database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE attendance_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date_key TEXT NOT NULL UNIQUE,
              first_check_in_time TEXT NOT NULL,
              last_check_in_time TEXT NOT NULL,
              first_check_in_utc TEXT NOT NULL,
              last_check_in_utc TEXT NOT NULL,
              note TEXT NOT NULL DEFAULT '',
              timezone TEXT NOT NULL,
              timezone_offset_minutes INTEGER NOT NULL,
              attendance_source TEXT NOT NULL DEFAULT 'normal',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE attendance_settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              minimum_minutes INTEGER NOT NULL,
              first_window_start INTEGER NOT NULL,
              first_window_end INTEGER NOT NULL,
              last_window_start INTEGER NOT NULL,
              last_window_end INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE excluded_time_ranges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_minute INTEGER NOT NULL,
              end_minute INTEGER NOT NULL,
              sort_order INTEGER NOT NULL
            )
          ''');
          await _createHolidayTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createHolidayTables(db);
          }
          if (oldVersion < 3) {
            await _migrateAttendanceRecords(db);
          }
          if (oldVersion < 4) {
            await _addUtcTimeColumns(db);
          }
        },
      ),
    );
    return AttendanceDatabase._(database);
  }

  static Future<void> _migrateAttendanceRecords(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE attendance_records RENAME TO attendance_records_legacy',
    );
    await db.execute('''
      CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL UNIQUE,
        first_check_in_time TEXT NOT NULL,
        last_check_in_time TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
              timezone TEXT NOT NULL,
        attendance_source TEXT NOT NULL DEFAULT 'normal',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    final rows = await db.query('attendance_records_legacy');
    for (final row in rows) {
      final first = DateTime.parse(row['first_check_in']! as String);
      final last = DateTime.parse(row['last_check_in']! as String);
      await db.insert('attendance_records', {
        'id': row['id'],
        'date_key': _dateKey(first),
        'first_check_in_time': _time(first),
        'last_check_in_time': _time(last),
        'note': row['note'],
        'timezone': AttendanceTimeService.formatOffset(first.timeZoneOffset),
        'attendance_source': row['is_manual'] == 1 ? 'resign' : 'normal',
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      });
    }
    await db.execute('DROP TABLE attendance_records_legacy');
  }

  static Future<void> _addUtcTimeColumns(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE attendance_records ADD COLUMN first_check_in_utc TEXT',
    );
    await db.execute(
      'ALTER TABLE attendance_records ADD COLUMN last_check_in_utc TEXT',
    );
    await db.execute(
      'ALTER TABLE attendance_records ADD COLUMN timezone_offset_minutes INTEGER',
    );
    final rows = await db.query('attendance_records');
    for (final row in rows) {
      final timezone =
          row['timezone'] as String? ??
          AttendanceTimeService.formatOffset(DateTime.now().timeZoneOffset);
      final offset = AttendanceTimeService.parseOffsetMinutes(timezone);
      final date = _parseDate(row['date_key']! as String);
      final first = _combine(date, row['first_check_in_time']! as String);
      final last = _combine(date, row['last_check_in_time']! as String);
      await db.update(
        'attendance_records',
        {
          'first_check_in_utc': AttendanceTimeService.utcFromLocal(
            first,
            offset,
          ).toIso8601String(),
          'last_check_in_utc': AttendanceTimeService.utcFromLocal(
            last,
            offset,
          ).toIso8601String(),
          'timezone_offset_minutes': offset,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  static String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String value) {
    final parts = value.split(RegExp(r'[-/]'));
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime _combine(DateTime date, String value) {
    final parts = value.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static Future<void> _createHolidayTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE holiday_calendar_years (
        year INTEGER PRIMARY KEY,
        region TEXT NOT NULL,
        source TEXT NOT NULL,
        imported_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE holiday_calendar (
        date_key TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (year) REFERENCES holiday_calendar_years(year)
      )
    ''');
    await db.execute(
      'CREATE INDEX holiday_calendar_year_idx ON holiday_calendar(year)',
    );
  }
}
