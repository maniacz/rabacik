import 'package:flutter/material.dart';

/// Helper do wykrywania daty w tekście w różnych formatach
class DateTextHelper {
  /// Sprawdza czy tekst zawiera podaną datę przy użyciu wyrażenia regex
  static bool containsDate(String text, DateTime date, {RegExp? regExp}) {
    final normalized = text.replaceAll('O', '0');
    // Użyj domyślnego regexa jeśli nie podano
    final dateRegExp = regExp ?? RegExp(r'(?<!\d)(?:20\d{2}[-.](?:0\d|1[0-2]|O\d)[-.](?:0\d|[12]\d|3[01])|(?:0?\d|[12]\d|3[01])[-.](?:0\d|1[0-2]|O\d)[-.]20\d{2}|(?:0?\d|[12]\d|3[01])[-.](?:0\d|1[0-2]|O\d))(?!\d)');
    final matches = dateRegExp.allMatches(normalized);
    for (final match in matches) {
      final rawTextDate = match.group(0);
      if (rawTextDate != null) {
        // Spróbuj sparsować datę z tekstu
        // final parsed = _parseDate(rawTextDate);
        // if (parsed != null && _isSameDay(rawTextDate, date)) {
          final result = _isSameDay(rawTextDate, date);
          return result;
        // }
      }
    }
    return false;
  }

  static DateTime? _parseDate(String input) {
    // yyyy-MM-dd, yyyy/MM/dd, yyyy.MM.dd
    final isoMatch = RegExp(r'^(\d{4})[-/.](\d{2})[-/.](\d{2})$').firstMatch(input);
    if (isoMatch != null) {
      final dt = DateTime.tryParse('${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}');
      if (dt != null) return dt;
    }
    // dd-MM-yyyy, dd/MM/yyyy, dd.MM.yyyy
    final euroMatch = RegExp(r'^(\d{2})[-/.](\d{2})[-/.](\d{4})$').firstMatch(input);
    if (euroMatch != null) {
      final day = int.tryParse(euroMatch.group(1)!);
      final month = int.tryParse(euroMatch.group(2)!);
      final year = int.tryParse(euroMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    // dd.MM or dd-MM or dd/MM (bez roku)
    final shortMatch = RegExp(r'^(\d{2})[-/.](\d{2})$').firstMatch(input);
    if (shortMatch != null) {
      final day = int.tryParse(shortMatch.group(1)!);
      final month = int.tryParse(shortMatch.group(2)!);
      if (day != null && month != null) {
        final now = DateTime.now();
        DateTime candidate = DateTime(now.year, month, day);
        if (candidate.isBefore(now.subtract(const Duration(days: 1)))) {
          candidate = DateTime(now.year + 1, month, day);
        }
        return candidate;
      }
    }
    return null;
  }

  static bool _isSameDay(String rawTextDate, DateTime b) {
    bool isRawTextDateContainsYear = RegExp(r'\d{4}').hasMatch(rawTextDate);
    if (!isRawTextDateContainsYear) {
      final parsed = _parseDate(rawTextDate);
      return parsed != null && parsed.month == b.month && parsed.day == b.day;
    }
    final parsed = _parseDate(rawTextDate);
    return parsed != null &&  parsed.year == b.year && parsed.month == b.month && parsed.day == b.day;
  }
}
