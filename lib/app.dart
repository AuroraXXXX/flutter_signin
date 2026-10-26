import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/holiday_calendar_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/services/holiday_calendar_service.dart';
import 'ui/app_store.dart';
import 'ui/app_shell.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.attendanceRepository,
    required this.settingsRepository,
    required this.holidayCalendarRepository,
    required this.holidayCalendarService,
  });

  final AttendanceRepository attendanceRepository;
  final SettingsRepository settingsRepository;
  final HolidayCalendarRepository holidayCalendarRepository;
  final HolidayCalendarService holidayCalendarService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppStore _store;

  @override
  void initState() {
    super.initState();
    _store = AppStore(
      attendanceRepository: widget.attendanceRepository,
      settingsRepository: widget.settingsRepository,
      holidayCalendarRepository: widget.holidayCalendarRepository,
      holidayCalendarService: widget.holidayCalendarService,
    )..initialize();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
