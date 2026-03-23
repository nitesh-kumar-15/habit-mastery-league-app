import 'package:intl/intl.dart';

/// normalized calendar dates as `yyyy-MM-dd` (local timezone).
class AppDates {
  AppDates._();

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime d) {
    // strip time so comparisons stay day-based.
    final x = DateTime(d.year, d.month, d.day);
    return _fmt.format(x);
  }

  static DateTime parseDate(String ymd) {
    // parse strict yyyy-mm-dd values from sqlite.
    final p = ymd.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  // expose a single normalized today helper.
  static String today() => formatDate(DateTime.now());

  static bool isWeekday(DateTime d) => d.weekday >= DateTime.monday && d.weekday <= DateTime.friday;
}
