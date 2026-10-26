import 'package:signals/signals.dart';

import '../domain/models/attendance_evaluation.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/attendance_settings.dart';
import '../domain/models/holiday_calendar.dart';
import '../domain/models/monthly_attendance_summary.dart';
import '../domain/repositories/attendance_repository.dart';
import '../domain/repositories/holiday_calendar_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/holiday_calendar_service.dart';
import '../domain/use_cases/calculate_attendance.dart';
import '../domain/use_cases/calculate_monthly_summary.dart';

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

  final records = signal<List<AttendanceRecord>>(const []);
  final settings = signal(const AttendanceSettings());
  final isLoading = signal(true);
  final loadError = signal<String?>(null);
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
      calculator(record, settings.value);

  Future<void> initialize() async {
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    try {
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
    final existing = await attendanceRepository.getByDate(now);
    final record = existing == null
        ? AttendanceRecord(date: now, firstCheckIn: now, lastCheckIn: now)
        : existing.copyWith(lastCheckIn: now);
    await attendanceRepository.save(record);
    await _reloadRecords();
    return existing == null;
  }

  Future<void> saveManualRecord(AttendanceRecord record) async {
    if (record.lastCheckIn.isBefore(record.firstCheckIn)) {
      throw ArgumentError('末次签到时间不能早于首次签到时间');
    }
    await attendanceRepository.save(record.copyWith(isManual: true));
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
}
