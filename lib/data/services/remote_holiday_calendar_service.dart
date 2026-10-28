import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/holiday_calendar.dart';
import '../../domain/services/holiday_calendar_service.dart';

/// 从远程 holiday-calendar 数据源获取并校验中国年度作息表。
class RemoteHolidayCalendarService implements HolidayCalendarService {
  RemoteHolidayCalendarService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _sources = [
    'https://gcore.jsdelivr.net/gh/cg-zhou/holiday-calendar@main/data/CN',
    'https://unpkg.com/holiday-calendar/data/CN',
  ];

  @override
  Future<HolidayCalendarYear> fetchYear(int year) async {
    Object? lastError;
    // 第一个地址失败时尝试备用 CDN，提高同步成功率。
    for (final baseUrl in _sources) {
      final uri = Uri.parse('$baseUrl/$year.json');
      try {
        final response = await _client.get(uri);
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return parseJson(
          utf8.decode(response.bodyBytes),
          source: uri.toString(),
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('$year 年作息表下载失败：$lastError');
  }

  @override
  HolidayCalendarYear parseJson(String json, {required String source}) {
    // 解析后进行结构、地区、日期范围和重复日期校验，避免脏数据进入数据库。
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 顶层必须是对象');
    }
    final year = decoded['year'];
    final region = decoded['region'];
    final rawDates = decoded['dates'];
    if (year is! int || region != 'CN' || rawDates is! List) {
      throw const FormatException('JSON 必须包含合法的 year、region=CN 和 dates');
    }

    final keys = <String>{};
    final dates = <HolidayDate>[];
    for (final rawDate in rawDates) {
      if (rawDate is! Map<String, dynamic>) {
        throw const FormatException('dates 中的项目必须是对象');
      }
      final dateText = rawDate['date'];
      final typeText = rawDate['type'];
      final name = rawDate['name_cn'] ?? rawDate['name'];
      if (dateText is! String || typeText is! String || name is! String) {
        throw const FormatException('日期项目缺少 date、name 或 type');
      }
      final date = _parseDate(dateText);
      if (date.year != year) {
        throw FormatException('$dateText 不属于 $year 年');
      }
      if (!keys.add(dateText)) {
        throw FormatException('存在重复日期：$dateText');
      }
      dates.add(
        HolidayDate(
          date: date,
          name: name,
          type: HolidayDateType.parse(typeText),
        ),
      );
    }
    dates.sort((a, b) => a.date.compareTo(b.date));
    return HolidayCalendarYear(
      year: year,
      region: region as String,
      dates: List.unmodifiable(dates),
      source: source,
      importedAt: DateTime.now(),
    );
  }

  DateTime _parseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('日期格式错误：$value');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('日期无效：$value');
    }
    return date;
  }
}
