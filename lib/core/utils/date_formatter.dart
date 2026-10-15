import 'package:intl/intl.dart';

/// Formatter and parser for transaction dates.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayWithDayFormat = DateFormat('EEE, dd/MM/yyyy');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Formats DateTime to 'dd/MM/yyyy'
  static String format(DateTime date) => _displayFormat.format(date);

  /// Formats DateTime to 'Mon, 15/10/2026'
  static String formatWithDay(DateTime date) => _displayWithDayFormat.format(date);

  /// Day of week short label (e.g. Mon, Tue, Wed)
  static String dayOfWeek(DateTime date) => _dayOfWeekFormat.format(date);

  /// Month and year (e.g. October 2026)
  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  /// Parses diverse date formats found on supermarket receipts.
  /// Supported:
  /// - 15/10/2026, 15-10-2026, 15.10.2026
  /// - 2026-10-15, 2026/10/15
  /// - 15/10/26
  /// - Ngày 15 tháng 10 năm 2026
  static DateTime? parse(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final trimmed = rawText.trim();

    // 1. Vietnamese text pattern: "Ngày 15 tháng 10 năm 2026"
    final vnPattern = RegExp(
      r'ng[aà]y\s+(\d{1,2})\s+th[aá]ng\s+(\d{1,2})\s+n[aă]m\s+(\d{4})',
      caseSensitive: false,
    );
    final vnMatch = vnPattern.firstMatch(trimmed);
    if (vnMatch != null) {
      final day = int.tryParse(vnMatch.group(1)!);
      final month = int.tryParse(vnMatch.group(2)!);
      final year = int.tryParse(vnMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return _safeCreateDate(year, month, day);
      }
    }

    // 2. Standard DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final dmyPattern = RegExp(
      r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b',
    );
    final dmyMatch = dmyPattern.firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      final year = int.tryParse(dmyMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return _safeCreateDate(year, month, day);
      }
    }

    // 3. ISO format YYYY-MM-DD or YYYY/MM/DD
    final ymdPattern = RegExp(
      r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
    );
    final ymdMatch = ymdPattern.firstMatch(trimmed);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!);
      final month = int.tryParse(ymdMatch.group(2)!);
      final day = int.tryParse(ymdMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return _safeCreateDate(year, month, day);
      }
    }

    // 4. Short year DD/MM/YY (e.g., 15/10/26)
    final dmyShortPattern = RegExp(
      r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})\b',
    );
    final dmyShortMatch = dmyShortPattern.firstMatch(trimmed);
    if (dmyShortMatch != null) {
      final day = int.tryParse(dmyShortMatch.group(1)!);
      final month = int.tryParse(dmyShortMatch.group(2)!);
      final shortYear = int.tryParse(dmyShortMatch.group(3)!);
      if (day != null && month != null && shortYear != null) {
        final fullYear = 2000 + shortYear;
        return _safeCreateDate(fullYear, month, day);
      }
    }

    return null;
  }

  static DateTime? _safeCreateDate(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Calculates start and end of week (Monday to Sunday)
  static DateTime getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static DateTime getEndOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day + (7 - date.weekday), 23, 59, 59);
  }
}

