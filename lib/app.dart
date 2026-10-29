import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/holiday_calendar_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/services/holiday_calendar_service.dart';
import 'ui/app_store.dart';
import 'ui/app_shell.dart';

/// 应用正式运行阶段的根 Widget。
///
/// [BootstrapApp] 负责完成数据库和 Repository 的异步初始化，初始化成功后
/// 才创建本 Widget。因此这里不负责打开数据库，而是接收已经准备好的依赖，
/// 创建应用状态并配置正式的 MaterialApp。
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.attendanceRepository,
    required this.settingsRepository,
    required this.holidayCalendarRepository,
    required this.holidayCalendarService,
  });

  /// 签到记录的持久化实现。
  final AttendanceRepository attendanceRepository;

  /// 考勤设置的持久化实现。
  final SettingsRepository settingsRepository;

  /// 节假日数据的本地缓存实现。
  final HolidayCalendarRepository holidayCalendarRepository;

  /// 节假日数据的远程获取和解析实现。
  final HolidayCalendarService holidayCalendarService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // AppStore 统一管理页面之间共享的签到、设置和作息表状态。
  // 它在 MyApp 的生命周期内只创建一次，避免页面之间各自维护重复状态。
  late final AppStore _store;

  @override
  void initState() {
    super.initState();
    // 创建状态容器后立即加载数据库中的设置和签到记录。
    // initialize() 是异步操作，加载状态由 AppStore 自己管理。
    _store = AppStore(
      attendanceRepository: widget.attendanceRepository,
      settingsRepository: widget.settingsRepository,
      holidayCalendarRepository: widget.holidayCalendarRepository,
      holidayCalendarService: widget.holidayCalendarService,
    )..initialize();
  }

  @override
  void dispose() {
    // AppStore 内部持有的 signals 在应用根 Widget 销毁时统一释放。
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 下面是正式运行阶段的应用配置；初始化阶段的临时 MaterialApp
      // 位于 BootstrapApp 中，仅用于显示加载或错误页面。
      title: '签到系统',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        // 考勤时间统一按 24 小时制展示，避免受到系统设置影响。
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: AppShell(store: _store),
    );
  }
}
