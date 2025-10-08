/// Advanced Search Service for Internet Archive
///
/// Executes advanced searches using the SearchQuery model and Internet Archive API.
/// Handles query building, API requests, and result parsing.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/search_query.dart';
import '../models/search_result.dart';
import '../models/rate_limit_status.dart';
import '../core/constants/internet_archive_constants.dart';
import '../services/ia_http_client.dart';
import '../services/rate_limiter.dart';

/// Service for executing advanced searches
///
/// Features:
/// - Builds complex queries using SearchQuery model
/// - Executes searches via Internet Archive API
/// - Parses and returns SearchResult objects
/// - Respects rate limits
/// - Provides progress tracking
class AdvancedSearchService extends ChangeNotifier {
  final IAHttpClient _client;

  bool _isSearching = false;
  int? _totalResults;
  List<SearchResult> _currentResults = [];
  String? _error;

  /// Current search state
  bool get isSearching => _isSearching;
  int? get totalResults => _totalResults;
  List<SearchResult> get currentResults => List.unmodifiable(_currentResults);
  String? get error => _error;

  AdvancedSearchService({IAHttpClient? client})
    : _client = client ?? IAHttpClient(rateLimiter: archiveRateLimiter);

  /// Execute a search query
  ///
  /// Returns a list of SearchResult objects matching the query
  Future<List<SearchResult>> search(SearchQuery query) async {
    _isSearching = true;
    _error = null;
    _totalResults = null;
    _currentResults = [];
    notifyListeners();

    try {
      // Build API URL
      final url = query.buildApiUrl(IAEndpoints.advancedSearch);

      if (kDebugMode) {
        print('[AdvancedSearchService] Searching: $url');
        print(
          '[AdvancedSearchService] Query string: ${query.buildQueryString()}',
        );
      }

      // Execute search
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final responseData = jsonData['response'];

        // Parse total results
        _totalResults = responseData['numFound'] as int? ?? 0;

        // Parse results
        final docs = responseData['docs'] as List<dynamic>? ?? [];
        _currentResults = docs
            .map((doc) => SearchResult.fromJson(doc as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print(
            '[AdvancedSearchService] Found $_totalResults total results, returned ${_currentResults.length}',
          );
        }

        _isSearching = false;
        notifyListeners();

        return List.unmodifiable(_currentResults);
      } else {
        throw Exception('Search API returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AdvancedSearchService] Error executing search: $e');
      }
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Execute a paginated search
  ///
  /// Returns results for a specific page
  Future<SearchResultPage> searchPaginated(
    SearchQuery query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final paginatedQuery = query.copyWith(page: page, rows: pageSize);

    final results = await search(paginatedQuery);

    return SearchResultPage(
      results: results,
      page: page,
      pageSize: pageSize,
      totalResults: _totalResults ?? 0,
      totalPages: _totalResults != null
          ? (_totalResults! / pageSize).ceil()
          : 0,
      hasNextPage: page * pageSize < (_totalResults ?? 0),
      hasPreviousPage: page > 1,
    );
  }

  /// Execute a simple text search
  ///
  /// Convenience method for basic searches
  Future<List<SearchResult>> simpleSearch(String query, {int rows = 20}) async {
    final searchQuery = SearchQuery.simple(query).copyWith(rows: rows);
    return search(searchQuery);
  }

  /// Search within a specific mediatype
  Future<List<SearchResult>> searchByMediatype(
    String mediatype, {
    String? query,
    int rows = 20,
  }) async {
    final searchQuery = SearchQuery(
      query: query,
      mediatypes: [mediatype],
      rows: rows,
    );
    return search(searchQuery);
  }

  /// Search with field-specific query
  ///
  /// Example: searchByField('title', 'dogs', query: 'animals')
  Future<List<SearchResult>> searchByField(
    String field,
    String value, {
    String? query,
    int rows = 20,
  }) async {
    final searchQuery = SearchQuery(
      query: query,
      fieldQueries: {field: value},
      rows: rows,
    );
    return search(searchQuery);
  }

  /// Get search suggestions based on query prefix
  ///
  /// Returns a limited number of results for autocomplete
  Future<List<SearchResult>> getSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      return [];
    }

    try {
      final searchQuery = SearchQuery.simple(prefix).copyWith(rows: 10);
      return await search(searchQuery);
    } catch (e) {
      if (kDebugMode) {
        print('[AdvancedSearchService] Error getting suggestions: $e');
      }
      return [];
    }
  }

  /// Clear current search results
  void clearResults() {
    _currentResults = [];
    _totalResults = null;
    _error = null;
    notifyListeners();
  }

  /// Get rate limit status
  Future<RateLimitStatus> getRateLimitStatus() async {
    return _client.getRateLimitStatus();
  }

  @override
  void dispose() {
    _currentResults.clear();
    super.dispose();
  }
}

/// Represents a page of search results
class SearchResultPage {
  final List<SearchResult> results;
  final int page;
  final int pageSize;
  final int totalResults;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const SearchResultPage({
    required this.results,
    required this.page,
    required this.pageSize,
    required this.totalResults,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// Get the range of results shown (e.g., "1-20 of 150")
  String get rangeDisplay {
    if (totalResults == 0) {
      return '0 results';
    }

    final start = (page - 1) * pageSize + 1;
    final end = (start + results.length - 1).clamp(0, totalResults);
    return '$start-$end of $totalResults';
  }

  /// Get page navigation info for display
  String get pageDisplay {
    if (totalPages == 0) {
      return 'Page 0 of 0';
    }
    return 'Page $page of $totalPages';
  }
}
