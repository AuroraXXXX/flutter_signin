import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'app.dart';
import 'data/repositories/sqlite_attendance_repository.dart';
import 'data/repositories/sqlite_holiday_calendar_repository.dart';
import 'data/repositories/sqlite_settings_repository.dart';
import 'data/services/attendance_database.dart';
import 'data/services/remote_holiday_calendar_service.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/holiday_calendar_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/services/holiday_calendar_service.dart';

class BootstrapApp extends SignalStatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  // 依赖异步初始化完成前为 null，界面此时显示加载状态。
  final _dependencies = signal<_AppDependencies?>(null);
  final _error = signal<String?>(null);
  final _isLoading = signal(true);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _dependencies.dispose();
    _error.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies.value;
    if (dependencies != null) {
      return MyApp(
        attendanceRepository: dependencies.attendanceRepository,
        settingsRepository: dependencies.settingsRepository,
        holidayCalendarRepository: dependencies.holidayCalendarRepository,
        holidayCalendarService: dependencies.holidayCalendarService,
      );
    }

    return MaterialApp(
      title: '签到系统',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading.value
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在初始化本地数据库…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text('应用启动失败'),
                      const SizedBox(height: 8),
                      SelectableText(
                        _error.value ?? '未知错误',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _initialize,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    batch(() {
      _isLoading.value = true;
      _error.value = null;
    });
    try {
      // 数据库只在启动阶段打开一次，Repository 共享同一个连接。
      final database = await AttendanceDatabase.open();
      _dependencies.value = _AppDependencies(
        attendanceRepository: SqliteAttendanceRepository(database),
        settingsRepository: SqliteSettingsRepository(database),
        holidayCalendarRepository: SqliteHolidayCalendarRepository(database),
        holidayCalendarService: RemoteHolidayCalendarService(),
      );
    } catch (error) {
      _error.value = error.toString();
    } finally {
      _isLoading.value = false;
    }
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.attendanceRepository,
    required this.settingsRepository,
    required this.holidayCalendarRepository,
    required this.holidayCalendarService,
  });

  final AttendanceRepository attendanceRepository;
  final SettingsRepository settingsRepository;
  final HolidayCalendarRepository holidayCalendarRepository;
  final HolidayCalendarService holidayCalendarService;
}
