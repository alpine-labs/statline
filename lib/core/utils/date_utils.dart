import 'package:intl/intl.dart';

/// Date formatting utilities for StatLine.
class StatLineDateUtils {
  StatLineDateUtils._();

  static final DateFormat _gameDateFormat = DateFormat('MMM d, y');
  static final DateFormat _gameDateTimeFormat = DateFormat('MMM d, y h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('M/d/yy');

  /// Formats a date as "Feb 17, 2026".
  static String formatGameDate(DateTime date) =>
      _gameDateFormat.format(date);

  /// Formats a date/time as "Feb 17, 2026 7:00 PM".
  static String formatGameDateTime(DateTime date) =>
      _gameDateTimeFormat.format(date);

  /// Formats a date as "2/17/26".
  static String formatShortDate(DateTime date) =>
      _shortDateFormat.format(date);

  /// Returns an ISO 8601 string representation of [date].
  static String formatIso(DateTime date) => date.toUtc().toIso8601String();

  /// Parses an ISO 8601 string into a [DateTime].
  static DateTime parseIso(String iso) => DateTime.parse(iso);
}
