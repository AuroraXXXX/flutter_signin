import 'package:signals/signals.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../domain/models/attendance_evaluation.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/attendance_settings.dart';
import '../domain/models/holiday_calendar.dart';
import '../domain/models/monthly_attendance_summary.dart';
import '../domain/repositories/attendance_repository.dart';
import '../domain/repositories/holiday_calendar_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/holiday_calendar_service.dart';
import '../domain/services/attendance_csv_service.dart';
import '../domain/services/attendance_time_service.dart';
import '../domain/use_cases/calculate_attendance.dart';
import '../domain/use_cases/calculate_monthly_summary.dart';

/// 应用级状态容器，连接 UI、领域规则和持久化层。
class AppStore {
  AppStore({
    required this.attendanceRepository,
    required this.settingsRepository,
    required this.holidayCalendarRepository,
    required this.holidayCalendarService,
    this.calculator = const CalculateAttendance(),
    this.monthlyCalculator = const CalculateMonthlySummary(),
  }) {
    todayRecord = computed(() => recordFor(DateTime.now()));
    monthlyRecords = computed(() {
      final month = selectedHistoryMonth.value;
      return List.unmodifiable(
        records.value.where(
          (record) =>
              record.date.year == month.year &&
              record.date.month == month.month,
        ),
      );
    });
    monthlySummary = computed(() {
      final calendar = holidayCalendar.value;
      final month = selectedHistoryMonth.value;
      if (calendar == null || calendar.year != month.year) return null;
      return monthlyCalculator(
        month: month,
        now: DateTime.now(),
        records: records.value,
        settings: settings.value,
        calendar: calendar,
      );
    });
  }

  final AttendanceRepository attendanceRepository;
  final SettingsRepository settingsRepository;
  final HolidayCalendarRepository holidayCalendarRepository;
  final HolidayCalendarService holidayCalendarService;
  final CalculateAttendance calculator;
  final CalculateMonthlySummary monthlyCalculator;
  static const _attendanceCsv = AttendanceCsvService();

  // 对外暴露不可变列表，避免页面直接修改共享状态。
  final records = signal<List<AttendanceRecord>>(const []);
  final settings = signal(const AttendanceSettings());
  final isLoading = signal(true);
  final loadError = signal<String?>(null);
  // 月份统一归一化为该月第一天，便于比较和加载年度作息表。
  final selectedHistoryMonth = signal(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final holidayCalendar = signal<HolidayCalendarYear?>(null);
  final isCalendarLoading = signal(false);
  final calendarError = signal<String?>(null);
  late final Computed<AttendanceRecord?> todayRecord;
  late final Computed<List<AttendanceRecord>> monthlyRecords;
  late final Computed<MonthlyAttendanceSummary?> monthlySummary;

  AttendanceRecord? recordFor(DateTime date) {
    for (final record in records.value) {
      if (_sameDate(record.date, date)) return record;
    }
    return null;
  }

  AttendanceEvaluation evaluate(AttendanceRecord record) =>
      calculator(record, settings.value, now: DateTime.now());

  Future<void> initialize() async {
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    try {
      // 设置和记录都加载成功后才一次性更新 UI，减少中间状态闪烁。
      final loadedSettings = await settingsRepository.get();
      final loadedRecords = await attendanceRepository.getAll();
      batch(() {
        settings.value = loadedSettings;
        records.value = List.unmodifiable(loadedRecords);
      });
    } catch (error) {
      loadError.value = '数据加载失败：$error';
    } finally {
      isLoading.value = false;
    }
    if (loadError.value == null) {
      await loadCalendarForSelectedMonth();
    }
  }

  Future<void> selectHistoryMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    if (normalized.isAfter(
      DateTime(DateTime.now().year, DateTime.now().month),
    )) {
      return;
    }
    selectedHistoryMonth.value = normalized;
    await loadCalendarForSelectedMonth();
  }

  Future<void> loadCalendarForSelectedMonth({bool forceSync = false}) async {
    final year = selectedHistoryMonth.value.year;
    final previousCalendar = holidayCalendar.value;
    batch(() {
      isCalendarLoading.value = true;
      calendarError.value = null;
    });
    try {
      HolidayCalendarYear? calendar;
      // 默认优先使用本地缓存；用户明确同步时才跳过缓存。
      if (!forceSync) {
        calendar = await holidayCalendarRepository.getYear(year);
      }
      if (calendar == null) {
        calendar = await holidayCalendarService.fetchYear(year);
        await holidayCalendarRepository.saveYear(calendar);
      }
      if (selectedHistoryMonth.value.year == year) {
        holidayCalendar.value = calendar;
      }
    } catch (error) {
      if (selectedHistoryMonth.value.year == year) {
        if (previousCalendar?.year != year) {
          holidayCalendar.value = null;
        }
        calendarError.value = error.toString();
      }
    } finally {
      isCalendarLoading.value = false;
    }
  }

  Future<HolidayCalendarYear> importHolidayCalendarJson(String json) async {
    final calendar = holidayCalendarService.parseJson(json, source: '手动导入');
    await holidayCalendarRepository.saveYear(calendar);
    if (calendar.year == selectedHistoryMonth.value.year) {
      batch(() {
        holidayCalendar.value = calendar;
        calendarError.value = null;
      });
    }
    return calendar;
  }

  Future<bool> checkIn({DateTime? at}) async {
    final now = at ?? DateTime.now();
    final nowUtc = now.toUtc();
    // 不能简单按设备当前日期查找，因为旧记录可能保存了不同的时区。
    final allRecords = await attendanceRepository.getAll();
    AttendanceRecord? existing;
    for (final candidate in allRecords) {
      final offset = AttendanceTimeService.parseOffsetMinutes(
        candidate.timezone,
      );
      final localNow = AttendanceTimeService.localWallTime(nowUtc, offset);
      if (_sameDate(localNow, candidate.date)) {
        existing = candidate;
        break;
      }
    }
    // 第一次点击创建记录，之后的点击只更新末次签到时间。
    final record = existing == null
        ? AttendanceRecord(
            date: now,
            firstCheckIn: now,
            lastCheckIn: now,
            timezone: AttendanceTimeService.formatOffset(now.timeZoneOffset),
            firstCheckInUtc: nowUtc,
            lastCheckInUtc: nowUtc,
          )
        : existing.copyWith(
            lastCheckIn: AttendanceTimeService.localWallTime(
              nowUtc,
              AttendanceTimeService.parseOffsetMinutes(existing.timezone),
            ),
            lastCheckInUtc: nowUtc,
          );
    await attendanceRepository.save(record);
    await _reloadRecords();
    return existing == null;
  }

  Future<void> saveManualRecord(AttendanceRecord record) async {
    if (record.lastCheckIn.isBefore(record.firstCheckIn)) {
      throw ArgumentError('末次签到时间不能早于首次签到时间');
    }
    // 补签时间来自用户选择的本地墙上时间，因此保存时重新生成 UTC 值。
    final timezone = AttendanceTimeService.formatOffset(
      DateTime.now().timeZoneOffset,
    );
    final offset = AttendanceTimeService.parseOffsetMinutes(timezone);
    await attendanceRepository.save(
      record.copyWith(
        attendanceSource: AttendanceSource.resign,
        timezone: timezone,
        firstCheckInUtc: AttendanceTimeService.utcFromLocal(
          record.firstCheckIn,
          offset,
        ),
        lastCheckInUtc: AttendanceTimeService.utcFromLocal(
          record.lastCheckIn,
          offset,
        ),
      ),
    );
    await _reloadRecords();
  }

  Uint8List exportAttendanceCsv({DateTime? startDate, DateTime? endDate}) {
    final filtered = records.value.where((record) {
      final date = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final start = startDate == null
          ? null
          : DateTime(startDate.year, startDate.month, startDate.day);
      final end = endDate == null
          ? null
          : DateTime(endDate.year, endDate.month, endDate.day);
      return (start == null || !date.isBefore(start)) &&
          (end == null || !date.isAfter(end));
    }).toList();
    final statuses = <String, List<AttendanceStatus>>{};
    for (final record in filtered) {
      statuses[_dateKey(record.date)] = evaluate(record).statuses;
    }
    return Uint8List.fromList(
      utf8.encode(_attendanceCsv.encode(filtered, statuses: statuses)),
    );
  }

  List<AttendanceRecord> parseAttendanceCsv(String csv) =>
      _attendanceCsv.decode(csv);

  Future<void> saveImportedAttendance(
    List<AttendanceRecord> imported, {
    required bool overwrite,
  }) async {
    await attendanceRepository.saveAll(imported, overwrite: overwrite);
    await _reloadRecords();
  }

  Future<void> deleteRecord(AttendanceRecord record) async {
    final id = record.id;
    if (id == null) return;
    await attendanceRepository.delete(id);
    await _reloadRecords();
  }

  Future<void> saveSettings(AttendanceSettings settings) async {
    await settingsRepository.save(settings);
    this.settings.value = settings;
  }

  Future<void> _reloadRecords() async {
    records.value = List.unmodifiable(await attendanceRepository.getAll());
  }

  void dispose() {
    todayRecord.dispose();
    monthlyRecords.dispose();
    monthlySummary.dispose();
    records.dispose();
    settings.dispose();
    isLoading.dispose();
    loadError.dispose();
    selectedHistoryMonth.dispose();
    holidayCalendar.dispose();
    isCalendarLoading.dispose();
    calendarError.dispose();
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
