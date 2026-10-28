import '../models/holiday_calendar.dart';

/// 年度作息表的本地持久化抽象。
abstract interface class HolidayCalendarRepository {
  Future<HolidayCalendarYear?> getYear(int year);

  Future<void> saveYear(HolidayCalendarYear calendar);
}
