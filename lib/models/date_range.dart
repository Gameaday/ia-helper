/// Date Range Model for Internet Archive Search Filtering
///
/// Represents a date range for filtering search results.
/// Supports Internet Archive date query syntax.
///
/// API Reference: https://archive.org/developers/search.html#date-range
library;

import 'package:flutter/foundation.dart';

/// A date range for filtering search results
///
/// Internet Archive supports date range queries in the format:
/// - date:[YYYY-MM-DD TO YYYY-MM-DD]
/// - year:[YYYY TO YYYY]
@immutable
class DateRange {
  /// Start date (inclusive)
  final DateTime start;

  /// End date (inclusive)
  final DateTime end;

  /// Field to search (date, year, publicdate, addeddate, etc.)
  final String field;

  const DateRange({required this.start, required this.end, this.field = 'date'})
    : assert(field != '');

  /// Create a date range from year values
  factory DateRange.fromYears(int startYear, int endYear) {
    return DateRange(
      start: DateTime(startYear, 1, 1),
      end: DateTime(endYear, 12, 31),
      field: 'year',
    );
  }

  /// Create a date range for a single year
  factory DateRange.year(int year) {
    return DateRange.fromYears(year, year);
  }

  /// Create a date range for the last N days
  factory DateRange.lastDays(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return DateRange(start: start, end: end);
  }

  /// Create a date range for the last N months
  factory DateRange.lastMonths(int months) {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month - months, end.day);
    return DateRange(start: start, end: end);
  }

  /// Create a date range for the last N years
  factory DateRange.lastYears(int years) {
    final end = DateTime.now();
    final start = DateTime(end.year - years, end.month, end.day);
    return DateRange(start: start, end: end);
  }

  /// Create a date range for current year
  factory DateRange.thisYear() {
    final now = DateTime.now();
    return DateRange.year(now.year);
  }

  /// Create a date range for current month
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  /// Create a date range for current week
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekDay = now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekDay - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateRange(start: startOfWeek, end: endOfWeek);
  }

  /// Format date for Internet Archive API
  String _formatDate(DateTime date) {
    if (field == 'year') {
      return date.year.toString();
    }
    // Format: YYYY-MM-DD
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert to Internet Archive query string
  /// Returns: "date:[2020-01-01 TO 2020-12-31]"
  String toQueryString() {
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    return '$field:[$startStr TO $endStr]';
  }

  /// Get user-friendly display string
  String toDisplayString() {
    if (field == 'year' && start.year == end.year) {
      return '${start.year}';
    }

    if (start.year == end.year) {
      if (start.month == end.month) {
        if (start.day == end.day) {
          return '${start.month}/${start.day}/${start.year}';
        }
        return '${start.month}/${start.day} - ${end.day}, ${start.year}';
      }
      return '${start.month}/${start.day} - ${end.month}/${end.day}, ${start.year}';
    }

    return '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
  }

  /// Get duration in days
  int get durationInDays {
    return end.difference(start).inDays + 1; // +1 to include end date
  }

  /// Check if this range contains a specific date
  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// Check if this range overlaps with another range
  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Check if range is valid (start <= end)
  bool get isValid {
    return !start.isAfter(end);
  }

  /// Create a copy with modified fields
  DateRange copyWith({DateTime? start, DateTime? end, String? field}) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
      field: field ?? this.field,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'field': field,
    };
  }

  /// Create from JSON
  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      field: json['field'] as String? ?? 'date',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DateRange &&
        other.start == start &&
        other.end == end &&
        other.field == field;
  }

  @override
  int get hashCode => Object.hash(start, end, field);

  @override
  String toString() {
    return 'DateRange(start: $start, end: $end, field: $field)';
  }
}

/// Predefined date ranges for common use cases
class DateRangePresets {
  static DateRange get today {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static DateRange get yesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return DateRange(
      start: DateTime(yesterday.year, yesterday.month, yesterday.day),
      end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
    );
  }

  static DateRange get last7Days => DateRange.lastDays(7);
  static DateRange get last30Days => DateRange.lastDays(30);
  static DateRange get last90Days => DateRange.lastDays(90);
  static DateRange get last6Months => DateRange.lastMonths(6);
  static DateRange get lastYear => DateRange.lastYears(1);
  static DateRange get last5Years => DateRange.lastYears(5);
  static DateRange get last10Years => DateRange.lastYears(10);

  static DateRange get thisWeek => DateRange.thisWeek();
  static DateRange get thisMonth => DateRange.thisMonth();
  static DateRange get thisYear => DateRange.thisYear();

  /// Get all preset options
  static List<DateRangePreset> get all => [
    DateRangePreset('Today', today),
    DateRangePreset('Yesterday', yesterday),
    DateRangePreset('Last 7 days', last7Days),
    DateRangePreset('Last 30 days', last30Days),
    DateRangePreset('Last 90 days', last90Days),
    DateRangePreset('Last 6 months', last6Months),
    DateRangePreset('Last year', lastYear),
    DateRangePreset('Last 5 years', last5Years),
    DateRangePreset('This week', thisWeek),
    DateRangePreset('This month', thisMonth),
    DateRangePreset('This year', thisYear),
  ];
}

/// A named date range preset
class DateRangePreset {
  final String name;
  final DateRange range;

  const DateRangePreset(this.name, this.range);
}
