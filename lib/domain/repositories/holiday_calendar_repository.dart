import '../models/holiday_calendar.dart';

abstract interface class HolidayCalendarRepository {
  Future<HolidayCalendarYear?> getYear(int year);

  Future<void> saveYear(HolidayCalendarYear calendar);
}
