import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';

/// SQLite 数据库入口，负责打开数据库、建表和版本迁移。
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
          // 新数据库一次性创建当前版本所需的全部表。
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
      ),
    );
    return AttendanceDatabase._(database);
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
