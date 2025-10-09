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
import '../models/api_intensity_settings.dart';
import '../core/constants/internet_archive_constants.dart';
import '../services/ia_http_client.dart';
import '../services/rate_limiter.dart';
import '../services/thumbnail_cache_service.dart';
import '../screens/api_intensity_settings_screen.dart';

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
  /// Returns a list of SearchResult objects matching the query.
  /// Respects API intensity settings to optimize data usage and performance.
  Future<List<SearchResult>> search(SearchQuery query) async {
    _isSearching = true;
    _error = null;
    _totalResults = null;
    _currentResults = [];
    notifyListeners();

    try {
      // Load API intensity settings
      final settings = await ApiIntensitySettingsScreen.getSettings();

      // Adjust query based on API intensity
      final adjustedQuery = await _adjustQueryForIntensity(query, settings);

      // Build API URL
      final url = adjustedQuery.buildApiUrl(IAEndpoints.advancedSearch);

      if (kDebugMode) {
        print('[AdvancedSearchService] API Intensity: ${settings.level.name}');
        print('[AdvancedSearchService] Searching: $url');
        print(
          '[AdvancedSearchService] Query string: ${adjustedQuery.buildQueryString()}',
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

        // Preload thumbnails if enabled
        if (settings.loadThumbnails && settings.preloadMetadata) {
          _preloadThumbnails();
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

  /// Adjust query based on API intensity settings
  Future<SearchQuery> _adjustQueryForIntensity(
    SearchQuery query,
    ApiIntensitySettings settings,
  ) async {
    // Determine fields to request based on intensity level
    List<String> fields;
    int rows = query.rows;

    switch (settings.level) {
      case ApiIntensityLevel.full:
        // Request all fields for full experience
        fields = [
          'identifier',
          'title',
          'description',
          'creator',
          'date',
          'mediatype',
          'downloads',
          'item_size',
          'publicdate',
          'addeddate',
          'collection',
          'subject',
          'language',
          'avg_rating',
          'num_reviews',
          '__ia_thumb_url', // Thumbnail URL
        ];
        break;

      case ApiIntensityLevel.standard:
        // Request core fields for balanced experience
        fields = [
          'identifier',
          'title',
          'description',
          'creator',
          'date',
          'mediatype',
          'downloads',
          '__ia_thumb_url', // Thumbnail URL
        ];
        break;

      case ApiIntensityLevel.minimal:
        // Request only essential fields for fast loading
        fields = ['identifier', 'title', 'mediatype'];
        // Increase row count since payload is smaller
        rows = (rows * 2).clamp(1, 200);
        break;

      case ApiIntensityLevel.cacheOnly:
        // Cache-only mode - this should be handled at a higher level
        // Return minimal fields for cache lookup
        fields = ['identifier', 'title'];
        break;
    }

    // Apply field adjustments
    return query.copyWith(fields: fields, rows: rows);
  }

  /// Preload thumbnails for current results
  void _preloadThumbnails() {
    final thumbnailUrls = _currentResults
        .where((result) => result.thumbnailUrl != null)
        .map((result) => result.thumbnailUrl!)
        .toList();

    if (thumbnailUrls.isNotEmpty) {
      // Fire and forget - don't await
      ThumbnailCacheService().preloadThumbnails(thumbnailUrls).catchError((e) {
        if (kDebugMode) {
          print('[AdvancedSearchService] Thumbnail preload error: $e');
        }
      });
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
