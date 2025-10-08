/// Search Query Model for Internet Archive Advanced Search
///
/// Represents a complete search query with all parameters supported by the
/// Internet Archive Advanced Search API.
///
/// API Reference: https://archive.org/developers/search.html
/// Query Syntax: https://archive.org/advancedsearch.php
library;

import 'package:flutter/foundation.dart';
import 'date_range.dart';
import 'sort_option.dart';

/// A search query for the Internet Archive
///
/// Supports:
/// - Simple text queries
/// - Field-specific searches (title, creator, subject, etc.)
/// - Mediatype filtering
/// - Date range filtering
/// - Collection filtering
/// - Sort options
/// - Boolean operators (AND, OR, NOT)
@immutable
class SearchQuery {
  /// Main query string (searches across all fields)
  final String? query;

  /// Field-specific queries (e.g., title:dogs, creator:"Jane Smith")
  /// Supported fields: title, creator, subject, description, publisher,
  /// contributor, date, year, language, collection
  final Map<String, String> fieldQueries;

  /// Mediatype filters (movies, audio, texts, etc.)
  final List<String> mediatypes;

  /// Date range filter
  final DateRange? dateRange;

  /// Collection filter (can search within specific collections)
  final String? collection;

  /// Language filter (ISO 639-1 language codes)
  final List<String> languages;

  /// Sort option
  final SortOption sortBy;

  /// Number of results per page (default: 20, max: 10000)
  final int rows;

  /// Page number (1-indexed)
  final int page;

  /// Fields to return in results (null = use defaults)
  final List<String>? fields;

  /// Whether to include facets in results
  final bool includeFacets;

  const SearchQuery({
    this.query,
    this.fieldQueries = const {},
    this.mediatypes = const [],
    this.dateRange,
    this.collection,
    this.languages = const [],
    this.sortBy = SortOption.relevance,
    this.rows = 20,
    this.page = 1,
    this.fields,
    this.includeFacets = false,
  });

  /// Create an empty search query
  factory SearchQuery.empty() {
    return const SearchQuery();
  }

  /// Create a simple text search query
  factory SearchQuery.simple(String query) {
    return SearchQuery(query: query);
  }

  /// Create a field-specific search query
  factory SearchQuery.field(String field, String value) {
    return SearchQuery(fieldQueries: {field: value});
  }

  /// Create a mediatype filter query
  factory SearchQuery.mediatype(String mediatype) {
    return SearchQuery(mediatypes: [mediatype]);
  }

  /// Build the query string for the Internet Archive API
  ///
  /// Returns a Lucene-style query string that can be passed to the
  /// advancedsearch.php endpoint.
  ///
  /// Examples:
  /// - Simple: "dogs"
  /// - Field: "title:(dogs cats)"
  /// - Mediatype: "mediatype:movies"
  /// - Combined: "dogs AND title:cats AND mediatype:movies"
  /// - Date range: "date:[1990-01-01 TO 1999-12-31]"
  String buildQueryString() {
    final parts = <String>[];

    // Main query
    if (query != null && query!.trim().isNotEmpty) {
      parts.add(query!.trim());
    }

    // Field queries
    fieldQueries.forEach((field, value) {
      // Escape special characters and wrap in quotes if needed
      final escapedValue = _escapeValue(value);
      parts.add('$field:$escapedValue');
    });

    // Mediatype filters
    if (mediatypes.isNotEmpty) {
      if (mediatypes.length == 1) {
        parts.add('mediatype:${mediatypes.first}');
      } else {
        // Multiple mediatypes: (mediatype:movies OR mediatype:audio)
        final typeQueries = mediatypes.map((t) => 'mediatype:$t').join(' OR ');
        parts.add('($typeQueries)');
      }
    }

    // Date range
    if (dateRange != null) {
      parts.add(dateRange!.toQueryString());
    }

    // Collection filter
    if (collection != null && collection!.trim().isNotEmpty) {
      parts.add('collection:${collection!.trim()}');
    }

    // Language filters
    if (languages.isNotEmpty) {
      if (languages.length == 1) {
        parts.add('language:${languages.first}');
      } else {
        final langQueries = languages.map((l) => 'language:$l').join(' OR ');
        parts.add('($langQueries)');
      }
    }

    // Combine with AND
    return parts.isEmpty ? '*:*' : parts.join(' AND ');
  }

  /// Build the complete API URL for this query
  String buildApiUrl(String baseUrl) {
    final queryString = buildQueryString();
    final encodedQuery = Uri.encodeComponent(queryString);

    var url = '$baseUrl?q=$encodedQuery';
    url += '&rows=$rows';
    url += '&page=$page';
    url += '&output=json';

    // Add sort if not default
    if (sortBy != SortOption.relevance) {
      url += '&sort=${sortBy.toApiString()}';
    }

    // Add fields
    final fieldsList = fields ?? _defaultFields;
    for (final field in fieldsList) {
      url += '&fl[]=$field';
    }

    // Add facets if requested
    if (includeFacets) {
      url += '&facets=true';
    }

    return url;
  }

  /// Escape special characters in query values
  String _escapeValue(String value) {
    final trimmed = value.trim();

    // If contains spaces or special chars, wrap in parentheses
    if (trimmed.contains(' ') ||
        trimmed.contains(':') ||
        trimmed.contains('(') ||
        trimmed.contains(')')) {
      // Escape quotes
      final escaped = trimmed.replaceAll('"', '\\"');
      return '($escaped)';
    }

    return trimmed;
  }

  /// Default fields to return in search results
  static const List<String> _defaultFields = [
    'identifier',
    'title',
    'description',
    'mediatype',
    'downloads',
    'item_size',
    'publicdate',
    'creator',
    'collection',
  ];

  /// Check if this is an empty query (no filters applied)
  bool get isEmpty {
    return (query == null || query!.trim().isEmpty) &&
        fieldQueries.isEmpty &&
        mediatypes.isEmpty &&
        dateRange == null &&
        (collection == null || collection!.trim().isEmpty) &&
        languages.isEmpty;
  }

  /// Check if this query has any active filters
  bool get hasFilters {
    return mediatypes.isNotEmpty ||
        dateRange != null ||
        (collection != null && collection!.trim().isNotEmpty) ||
        languages.isNotEmpty ||
        fieldQueries.isNotEmpty;
  }

  /// Create a copy with modified fields
  SearchQuery copyWith({
    String? query,
    Map<String, String>? fieldQueries,
    List<String>? mediatypes,
    DateRange? dateRange,
    String? collection,
    List<String>? languages,
    SortOption? sortBy,
    int? rows,
    int? page,
    List<String>? fields,
    bool? includeFacets,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      fieldQueries: fieldQueries ?? this.fieldQueries,
      mediatypes: mediatypes ?? this.mediatypes,
      dateRange: dateRange ?? this.dateRange,
      collection: collection ?? this.collection,
      languages: languages ?? this.languages,
      sortBy: sortBy ?? this.sortBy,
      rows: rows ?? this.rows,
      page: page ?? this.page,
      fields: fields ?? this.fields,
      includeFacets: includeFacets ?? this.includeFacets,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'fieldQueries': fieldQueries,
      'mediatypes': mediatypes,
      'dateRange': dateRange?.toJson(),
      'collection': collection,
      'languages': languages,
      'sortBy': sortBy.name,
      'rows': rows,
      'page': page,
      'fields': fields,
      'includeFacets': includeFacets,
    };
  }

  /// Create from JSON
  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    return SearchQuery(
      query: json['query'] as String?,
      fieldQueries: Map<String, String>.from(json['fieldQueries'] as Map? ?? {}),
      mediatypes: List<String>.from(json['mediatypes'] as List? ?? []),
      dateRange: json['dateRange'] != null
          ? DateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
          : null,
      collection: json['collection'] as String?,
      languages: List<String>.from(json['languages'] as List? ?? []),
      sortBy: SortOption.values.firstWhere(
        (e) => e.name == json['sortBy'],
        orElse: () => SortOption.relevance,
      ),
      rows: json['rows'] as int? ?? 20,
      page: json['page'] as int? ?? 1,
      fields: json['fields'] != null
          ? List<String>.from(json['fields'] as List)
          : null,
      includeFacets: json['includeFacets'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchQuery &&
        other.query == query &&
        _mapEquals(other.fieldQueries, fieldQueries) &&
        _listEquals(other.mediatypes, mediatypes) &&
        other.dateRange == dateRange &&
        other.collection == collection &&
        _listEquals(other.languages, languages) &&
        other.sortBy == sortBy &&
        other.rows == rows &&
        other.page == page &&
        _listEquals(other.fields, fields) &&
        other.includeFacets == includeFacets;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      Object.hashAll(fieldQueries.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(mediatypes),
      dateRange,
      collection,
      Object.hashAll(languages),
      sortBy,
      rows,
      page,
      fields != null ? Object.hashAll(fields!) : null,
      includeFacets,
    );
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SearchQuery(query: $query, fieldQueries: $fieldQueries, '
        'mediatypes: $mediatypes, dateRange: $dateRange, '
        'collection: $collection, languages: $languages, '
        'sortBy: $sortBy, rows: $rows, page: $page)';
  }
}
