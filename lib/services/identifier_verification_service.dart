import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../utils/archive_identifier_normalizer.dart';
import '../models/identifier_cache_metrics.dart';

/// Suggestion type for smart search
enum SuggestionType {
  verifiedArchive, // Archive verified to exist
  possibleArchive, // Looks like archive ID but not verified
  recentSearch, // From search history
  keywordSearch, // Keyword search suggestion
}

/// Enhanced search suggestion with type and metadata
class SearchSuggestion {
  final String query;
  final SuggestionType type;
  final String? title; // Archive title if available
  final String? subtitle; // Additional info (file count, size, etc.)
  final bool isCaseVariant; // True if this is a case-corrected version

  const SearchSuggestion({
    required this.query,
    required this.type,
    this.title,
    this.subtitle,
    this.isCaseVariant = false,
  });

  /// Display text for this suggestion
  String get displayText => query;

  /// Icon for this suggestion type
  String get iconName {
    switch (type) {
      case SuggestionType.verifiedArchive:
        return 'archive';
      case SuggestionType.possibleArchive:
        return 'folder';
      case SuggestionType.recentSearch:
        return 'history';
      case SuggestionType.keywordSearch:
        return 'search';
    }
  }

  /// Description text for UI
  String get description {
    switch (type) {
      case SuggestionType.verifiedArchive:
        return isCaseVariant ? 'Archive (case corrected)' : 'Open archive';
      case SuggestionType.possibleArchive:
        return 'Check archive';
      case SuggestionType.recentSearch:
        return 'Recent search';
      case SuggestionType.keywordSearch:
        return 'Search all content';
    }
  }
}

/// Lightweight service for verifying archive identifiers
///
/// Uses HEAD requests and caching to minimize API calls while providing
/// fast feedback about whether an archive exists.
///
/// Features:
/// - Two-level normalization (standard/strict) with intelligent fallback
/// - Robust caching with hit/miss tracking
/// - Comprehensive metrics for API call savings
/// - Variant search strategy (primary → fallback → alternatives)
class IdentifierVerificationService {
  static const String _baseUrl = 'https://archive.org';
  static const Duration _hitCacheExpiration = Duration(
    hours: 2,
  ); // Hits last longer
  static const Duration _missCacheExpiration = Duration(
    minutes: 15,
  ); // Misses expire sooner
  static const int _maxCacheSize = 1000; // Prevent unbounded growth

  // Cache: identifier -> (exists, timestamp, title, variant type)
  final Map<String, _CacheEntry> _cache = {};

  // LRU tracking: identifier -> last access time
  final Map<String, DateTime> _accessTimes = {};

  // In-flight requests: prevent duplicate concurrent requests
  final Map<String, Future<SearchSuggestion?>> _inFlightRequests = {};

  // Metrics tracking
  IdentifierCacheMetrics _metrics = IdentifierCacheMetrics();

  /// Singleton instance
  static final IdentifierVerificationService instance =
      IdentifierVerificationService._internal();

  IdentifierVerificationService._internal();

  /// Get current cache metrics
  IdentifierCacheMetrics get metrics => _metrics;

  /// Check if identifier exists using two-level normalization strategy
  ///
  /// Strategy:
  /// 1. Try standard normalization (preserves case) - PRIMARY
  /// 2. Try strict normalization (lowercase) - FALLBACK
  /// 3. Try alternatives from both levels
  ///
  /// Features:
  /// - Deduplicates concurrent requests (cache stampede protection)
  /// - Different TTLs for hits (2h) and misses (15m)
  /// - LRU eviction when cache is full
  /// - Early exit for known misses
  ///
  /// Returns null if still checking, SearchSuggestion if exists, null if not found
  Future<SearchSuggestion?> verifyIdentifier(
    String identifier, {
    bool forceCheck = false,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) return null;

    // Get all search variants using two-level normalization
    final variants = ArchiveIdentifierNormalizer.getSearchVariants(normalized);
    if (variants.isEmpty) return null;

    // Check if there's already an in-flight request for any variant
    if (!forceCheck) {
      for (final variant in variants) {
        if (_inFlightRequests.containsKey(variant)) {
          // Reuse in-flight request (cache stampede protection)
          return _inFlightRequests[variant];
        }
      }
    }

    // Check cache for all variants first (unless force check)
    if (!forceCheck) {
      SearchSuggestion? cachedResult;
      bool allVariantsCachedAsMiss = true;

      for (int i = 0; i < variants.length; i++) {
        final variant = variants[i];
        if (_cache.containsKey(variant)) {
          final entry = _cache[variant]!;

          // Determine appropriate expiration based on entry type
          final expiration = entry.exists
              ? _hitCacheExpiration
              : _missCacheExpiration;

          // Check if cache entry is still valid
          if (DateTime.now().difference(entry.timestamp) < expiration) {
            if (entry.exists) {
              // Cache hit! Update access time for LRU
              _accessTimes[variant] = DateTime.now();

              // Determine variant type
              final isStandard = i == 0;
              final isStrict = i == 1 && variants.length > 1;
              final isAlternative = i > 1;

              // Track cache hit with variant type
              _metrics = _metrics.incrementHit(
                isStandard: isStandard,
                isStrict: isStrict,
                isAlternative: isAlternative,
              );

              cachedResult = SearchSuggestion(
                query: variant,
                type: SuggestionType.verifiedArchive,
                title: entry.title,
                subtitle: entry.subtitle,
                isCaseVariant: variant != normalized,
              );

              // Found a hit - return immediately
              break;
            }
            // Cached as miss - continue checking other variants
          } else {
            // Entry expired - remove from cache
            _cache.remove(variant);
            _accessTimes.remove(variant);
            _metrics = _metrics.incrementExpired();
            allVariantsCachedAsMiss = false;
          }
        } else {
          // Not in cache
          allVariantsCachedAsMiss = false;
        }
      }

      // If we found a cached hit, return it
      if (cachedResult != null) {
        return cachedResult;
      }

      // If all variants are cached as misses, return null immediately
      // (no need to make API calls - we know they all don't exist)
      if (allVariantsCachedAsMiss && variants.isNotEmpty) {
        return null;
      }
    }

    // No cache hit - perform actual check with variants
    // Create future and track it to prevent duplicate requests
    final requestFuture = _performCheckWithVariants(normalized, variants);

    // Track all variants as in-flight
    for (final variant in variants) {
      _inFlightRequests[variant] = requestFuture;
    }

    try {
      return await requestFuture;
    } finally {
      // Clean up in-flight tracking
      for (final variant in variants) {
        _inFlightRequests.remove(variant);
      }
    }
  }

  /// Perform actual HTTP check with variant strategy
  ///
  /// Tries variants in order: primary → fallback → alternatives
  /// Caches all results (both hits and misses)
  Future<SearchSuggestion?> _performCheckWithVariants(
    String original,
    List<String> variants,
  ) async {
    // Try each variant in order until one succeeds
    for (int i = 0; i < variants.length; i++) {
      final variant = variants[i];

      // Skip if already cached (shouldn't happen, but safety check)
      if (_cache.containsKey(variant)) continue;

      try {
        // Track API call (cache miss)
        _metrics = _metrics.incrementMiss();

        // Use metadata API for lightweight check (just title and basic info)
        final url = '$_baseUrl/metadata/$variant';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          // Archive exists! Parse minimal metadata
          final data = json.decode(response.body) as Map<String, dynamic>;
          final metadata = data['metadata'] as Map<String, dynamic>?;

          final title = metadata?['title'] as String?;
          final mediatype = metadata?['mediatype'] as String?;

          // Determine variant type for metrics
          final isStandard = i == 0; // First variant is standard
          final isStrict = i == 1 && variants.length > 1; // Second is strict
          final isAlternative = i > 1; // Rest are alternatives

          // Ensure cache size limit before adding
          _evictIfNeeded();

          // Cache the successful result
          _cache[variant] = _CacheEntry(
            exists: true,
            timestamp: DateTime.now(),
            title: title,
            subtitle: mediatype != null ? _formatMediatype(mediatype) : null,
            variantType: _getVariantType(isStandard, isStrict, isAlternative),
          );
          _accessTimes[variant] = DateTime.now();

          return SearchSuggestion(
            query: variant,
            type: SuggestionType.verifiedArchive,
            title: title,
            subtitle: mediatype != null ? _formatMediatype(mediatype) : null,
            isCaseVariant: variant != original,
          );
        } else if (response.statusCode == 404) {
          // Archive not found - cache the miss and try next variant
          _evictIfNeeded();

          _cache[variant] = _CacheEntry(
            exists: false,
            timestamp: DateTime.now(),
            variantType: 'miss',
          );
          _accessTimes[variant] = DateTime.now();
          // Continue to next variant
        } else {
          // Other error - don't cache, try next variant
          debugPrint('Unexpected status ${response.statusCode} for $variant');
          continue;
        }
      } catch (e) {
        // Network error or timeout - don't cache, try next variant
        debugPrint('Error verifying identifier $variant: $e');
        continue;
      }
    }

    // All variants failed
    return null;
  }

  /// Evict least recently used entries if cache is full
  void _evictIfNeeded() {
    if (_cache.length >= _maxCacheSize) {
      // Find least recently used entry
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _accessTimes.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        _cache.remove(oldestKey);
        _accessTimes.remove(oldestKey);
        _metrics = _metrics.incrementExpired();
      }
    }
  }

  /// Determine variant type for metrics
  String _getVariantType(bool isStandard, bool isStrict, bool isAlternative) {
    if (isStandard) return 'standard';
    if (isStrict) return 'strict';
    if (isAlternative) return 'alternative';
    return 'unknown';
  }

  /// Format mediatype for display
  String _formatMediatype(String mediatype) {
    switch (mediatype.toLowerCase()) {
      case 'texts':
        return 'Text';
      case 'movies':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'software':
        return 'Software';
      case 'image':
        return 'Image';
      case 'data':
        return 'Data';
      case 'web':
        return 'Web Archive';
      default:
        return mediatype;
    }
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
    _accessTimes.clear();
    _inFlightRequests.clear();
  }

  /// Clear specific identifier from cache
  void clearIdentifier(String identifier) {
    _cache.remove(identifier);
    _accessTimes.remove(identifier);
  }

  /// Reset metrics
  void resetMetrics() {
    _metrics = _metrics.reset();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'metrics': _metrics.toJson(),
      'hitRate': _metrics.hitRatePercent,
      'apiReduction': _metrics.apiReductionPercent,
      'standardSuccessRate':
          '${(_metrics.standardSuccessRate * 100).toStringAsFixed(1)}%',
      'strictSuccessRate':
          '${(_metrics.strictSuccessRate * 100).toStringAsFixed(1)}%',
      'alternativeSuccessRate':
          '${(_metrics.alternativeSuccessRate * 100).toStringAsFixed(1)}%',
    };
  }
}

/// Cache entry for identifier verification
class _CacheEntry {
  final bool exists;
  final DateTime timestamp;
  final String? title;
  final String? subtitle;
  final String variantType; // 'standard', 'strict', 'alternative', or 'miss'

  _CacheEntry({
    required this.exists,
    required this.timestamp,
    this.title,
    this.subtitle,
    this.variantType = 'unknown',
  });
}
