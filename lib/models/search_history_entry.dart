/// Search History Model for Internet Archive
///
/// Represents a search history entry for autocomplete and suggestions.
/// Lighter weight than SavedSearch - just tracks queries for suggestions.
library;

import 'package:flutter/foundation.dart';

/// A search history entry
@immutable
class SearchHistoryEntry {
  /// Unique identifier (database ID)
  final int? id;

  /// The search query text
  final String query;

  /// When this search was performed
  final DateTime timestamp;

  /// Number of results returned (if available)
  final int? resultCount;

  /// Mediatype filter used (if any)
  final String? mediatype;

  const SearchHistoryEntry({
    this.id,
    required this.query,
    required this.timestamp,
    this.resultCount,
    this.mediatype,
  });

  /// Create a new history entry
  factory SearchHistoryEntry.create({
    required String query,
    int? resultCount,
    String? mediatype,
  }) {
    return SearchHistoryEntry(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      mediatype: mediatype,
    );
  }

  /// Get display text for suggestions
  String get displayText => query;

  /// Get subtitle for suggestions (e.g., "2 weeks ago • 15 results")
  String get subtitle {
    final parts = <String>[];

    // Time ago
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      parts.add('Just now');
    } else if (difference.inHours < 1) {
      parts.add('${difference.inMinutes} min ago');
    } else if (difference.inDays < 1) {
      parts.add('${difference.inHours} hr ago');
    } else if (difference.inDays < 7) {
      parts.add('${difference.inDays} days ago');
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      parts.add('$weeks ${weeks == 1 ? "week" : "weeks"} ago');
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      parts.add('$months ${months == 1 ? "month" : "months"} ago');
    } else {
      final years = (difference.inDays / 365).floor();
      parts.add('$years ${years == 1 ? "year" : "years"} ago');
    }

    // Result count
    if (resultCount != null) {
      parts.add('$resultCount ${resultCount == 1 ? "result" : "results"}');
    }

    // Mediatype
    if (mediatype != null && mediatype!.isNotEmpty) {
      parts.add(mediatype!);
    }

    return parts.join(' • ');
  }

  /// Create a copy with modified fields
  SearchHistoryEntry copyWith({
    int? id,
    String? query,
    DateTime? timestamp,
    int? resultCount,
    String? mediatype,
  }) {
    return SearchHistoryEntry(
      id: id ?? this.id,
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
      resultCount: resultCount ?? this.resultCount,
      mediatype: mediatype ?? this.mediatype,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'result_count': resultCount,
      'mediatype': mediatype,
    };
  }

  /// Create from database map
  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      id: map['id'] as int?,
      query: map['query'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      resultCount: map['result_count'] as int?,
      mediatype: map['mediatype'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'mediatype': mediatype,
    };
  }

  /// Create from JSON
  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] as int?,
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int?,
      mediatype: json['mediatype'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchHistoryEntry &&
        other.id == id &&
        other.query == query &&
        other.timestamp == timestamp &&
        other.resultCount == resultCount &&
        other.mediatype == mediatype;
  }

  @override
  int get hashCode {
    return Object.hash(id, query, timestamp, resultCount, mediatype);
  }

  @override
  String toString() {
    return 'SearchHistoryEntry(id: $id, query: $query, timestamp: $timestamp)';
  }
}
