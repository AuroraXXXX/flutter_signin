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
import 'ui/core/app_logo.dart';

/// 应用启动引导 Widget。
///
/// 它位于 [MyApp] 外层，负责完成异步基础设施初始化：打开数据库、创建
/// Repository 和远程服务。初始化期间显示加载页面或错误页面，成功后再把
/// 这些依赖传递给 [MyApp]。
class BootstrapApp extends SignalStatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  // 依赖异步初始化完成前为 null，界面此时显示加载状态。
  // 使用 signal 是为了让初始化完成或失败后自动触发界面更新。
  final _dependencies = signal<_AppDependencies?>(null);

  // 保存启动失败原因，用于错误页面展示。
  final _error = signal<String?>(null);

  // true 表示正在打开数据库或创建启动依赖。
  final _isLoading = signal(true);

  @override
  void initState() {
    super.initState();
    // 启动阶段只执行一次初始化；失败后用户可通过“重试”再次调用它。
    _initialize();
  }

  @override
  void dispose() {
    // BootstrapApp 不再使用时释放 signals，避免保留无效的响应式监听。
    _dependencies.dispose();
    _error.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies.value;
    if (dependencies != null) {
      // 数据库和各项依赖已经准备好，切换到正式应用。
      return MyApp(
        attendanceRepository: dependencies.attendanceRepository,
        settingsRepository: dependencies.settingsRepository,
        holidayCalendarRepository: dependencies.holidayCalendarRepository,
        holidayCalendarService: dependencies.holidayCalendarService,
      );
    }

    // 初始化阶段使用一个临时 MaterialApp 承载加载页或错误页。
    // 初始化成功后，该 MaterialApp 会被 MyApp 内部的正式 MaterialApp 替换。
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
                      AppLogo(),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在初始化本地数据库…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(),
                      const SizedBox(height: 24),
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
    // 每次初始化或重试前，先清除旧错误并显示加载状态。
    batch(() {
      _isLoading.value = true;
      _error.value = null;
    });
    try {
      // 数据库只在启动阶段打开一次，三个 Repository 共享同一个连接。
      final database = await AttendanceDatabase.open();
      _dependencies.value = _AppDependencies(
        attendanceRepository: SqliteAttendanceRepository(database),
        settingsRepository: SqliteSettingsRepository(database),
        holidayCalendarRepository: SqliteHolidayCalendarRepository(database),
        holidayCalendarService: RemoteHolidayCalendarService(),
      );
    } catch (error) {
      // 数据库打开失败时不进入 MyApp，而是保留在错误页面，允许用户重试。
      _error.value = error.toString();
    } finally {
      _isLoading.value = false;
    }
  }
}

/// 启动完成后传递给 [MyApp] 的依赖集合。
///
/// 将这些对象集中保存，可以避免在 Widget 树中逐个传递数据库和 Repository，
/// 同时保证所有 Repository 使用同一个数据库连接。
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
