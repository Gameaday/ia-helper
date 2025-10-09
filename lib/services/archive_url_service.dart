import 'package:flutter/foundation.dart';
import '../core/constants/internet_archive_constants.dart';

/// Centralized Archive.org URL Service
///
/// Provides comprehensive URL construction and CORS handling for all Archive.org
/// API interactions. This service ensures:
/// - Consistent URL formatting across the app
/// - Platform-aware URL construction (web vs native)
/// - CORS-compliant URLs for web platform
/// - Archive.org best practices compliance
///
/// CORS Issues on Web Platform:
/// - CDN URLs (dn*.archive.org) do NOT have CORS headers
/// - Must use archive.org/download/ for file access on web
/// - services/img endpoint may fail on some items
/// - Use __ia_thumb.jpg via /download/ for reliable thumbnails
///
/// References:
/// - Archive.org API: https://archive.org/developers/
/// - CORS Policy: Only archive.org/download/ guarantees CORS headers
/// - CDN Behavior: CDN nodes do not serve CORS headers consistently
class ArchiveUrlService {
  static final ArchiveUrlService _instance = ArchiveUrlService._internal();
  factory ArchiveUrlService() => _instance;
  ArchiveUrlService._internal();

  // ============================================================================
  // METADATA & API URLS
  // ============================================================================

  /// Get metadata API URL for an identifier
  ///
  /// Example: https://archive.org/metadata/identifier
  String getMetadataUrl(String identifier) {
    return '${IAEndpoints.metadata}/${_sanitizeIdentifier(identifier)}';
  }

  /// Get details page URL for an identifier
  ///
  /// Example: https://archive.org/details/identifier
  String getDetailsUrl(String identifier) {
    return '${IAEndpoints.details}/${_sanitizeIdentifier(identifier)}';
  }

  /// Get advanced search URL with query parameters
  ///
  /// Example: https://archive.org/advancedsearch.php?q=title:test&output=json
  String getAdvancedSearchUrl(Map<String, String> params) {
    final uri = Uri.parse(IAEndpoints.advancedSearch);
    final queryParams = Map<String, String>.from(params);
    
    // Ensure output is JSON if not specified
    queryParams.putIfAbsent('output', () => 'json');
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Get simple search URL
  ///
  /// Example: https://archive.org/search.php?query=test
  String getSimpleSearchUrl(String query) {
    final uri = Uri.parse(IAEndpoints.search);
    return uri.replace(queryParameters: {'query': query}).toString();
  }

  // ============================================================================
  // DOWNLOAD URLS (CORS-SAFE FOR WEB)
  // ============================================================================

  /// Get download URL for a file
  ///
  /// Always returns archive.org/download/ format which has CORS headers.
  /// This is the ONLY reliable way to access files on web platform.
  ///
  /// Example: https://archive.org/download/identifier/filename.pdf
  String getDownloadUrl(String identifier, String filename) {
    return '${IAEndpoints.download}/${_sanitizeIdentifier(identifier)}/${_sanitizeFilename(filename)}';
  }

  /// Get directory listing URL for an archive
  ///
  /// Returns the download directory URL (useful for browsing files)
  /// Example: https://archive.org/download/identifier/
  String getDirectoryUrl(String identifier) {
    return '${IAEndpoints.download}/${_sanitizeIdentifier(identifier)}/';
  }

  // ============================================================================
  // THUMBNAIL URLS (PLATFORM-AWARE WITH CORS HANDLING)
  // ============================================================================

  /// Get the best thumbnail URL for the given identifier
  ///
  /// Platform-aware implementation:
  /// - Web: Returns CORS-friendly download endpoint
  /// - Native: Returns standard services/img endpoint (faster)
  ///
  /// Web uses __ia_thumb.jpg via /download/ to avoid CORS issues.
  String getThumbnailUrl(String identifier) {
    if (kIsWeb) {
      return getWebSafeThumbnailUrl(identifier);
    }
    return getNativeThumbnailUrl(identifier);
  }

  /// Get web-safe thumbnail URL (CORS-compliant)
  ///
  /// Uses archive.org/download/ which has CORS headers.
  /// Falls back to __ia_thumb.jpg which is generated for most items.
  ///
  /// Example: https://archive.org/download/identifier/__ia_thumb.jpg
  String getWebSafeThumbnailUrl(String identifier) {
    return '${IAEndpoints.download}/${_sanitizeIdentifier(identifier)}/__ia_thumb.jpg';
  }

  /// Get native platform thumbnail URL (services/img endpoint)
  ///
  /// Faster endpoint that works on native platforms without CORS issues.
  /// Example: https://archive.org/services/img/identifier
  String getNativeThumbnailUrl(String identifier) {
    return '${IAEndpoints.thumbnail}/${_sanitizeIdentifier(identifier)}';
  }

  /// Get multiple thumbnail URLs to try in order (web platform)
  ///
  /// Returns a list of URLs in priority order:
  /// 1. Download endpoint with __ia_thumb.jpg (most reliable on web)
  /// 2. Services/img endpoint (may work for some items)
  ///
  /// Caller should try these in order and use first successful load.
  List<String> getThumbnailUrlsToTry(String identifier) {
    if (kIsWeb) {
      return [
        getWebSafeThumbnailUrl(identifier),
        getNativeThumbnailUrl(identifier), // May work despite CORS
      ];
    }
    return [
      getNativeThumbnailUrl(identifier),
    ];
  }

  // ============================================================================
  // CORS FIX: CDN URL REWRITING
  // ============================================================================

  /// Fix CDN URLs to use standardized archive.org/download/ format
  ///
  /// Archive.org CDN nodes (dn*.archive.org, ia*.archive.org) are:
  /// - Regional/distributed servers that may be slower or less reliable
  /// - Do NOT serve CORS headers (blocks web platform access)
  /// - Create inconsistency across platforms
  ///
  /// This method detects and rewrites CDN URLs to use the canonical
  /// archive.org/download/ endpoint, which:
  /// - Works consistently across ALL platforms (web, mobile, desktop)
  /// - Has proper CORS headers for web
  /// - Is the official, documented API endpoint
  /// - Provides better reliability and performance
  ///
  /// Examples:
  /// - Input:  https://dn720003.ca.archive.org/some/path/file.jpg
  /// - Output: https://archive.org/download/identifier/file.jpg
  ///
  /// - Input:  https://ia801408.us.archive.org/21/items/identifier/file.jpg
  /// - Output: https://archive.org/download/identifier/file.jpg
  ///
  /// Parameters:
  /// - url: The URL to check and potentially rewrite
  /// - identifier: The archive identifier (required for reconstruction)
  ///
  /// Returns:
  /// - Rewritten URL if CDN detected, original URL otherwise
  String fixCorsUrl(String url, String identifier) {
    // Already using archive.org/download/ - no fix needed
    if (url.startsWith('https://archive.org/download/')) {
      return url;
    }

    // Not an archive.org URL at all
    if (!url.contains('.archive.org')) {
      return url;
    }

    // Detect CDN patterns and rewrite for ALL platforms
    // This ensures consistency and uses the official API endpoint
    if (_isCdnUrl(url)) {
      final filename = url.split('/').last;
      final fixedUrl = getDownloadUrl(identifier, filename);
      
      if (kDebugMode) {
        debugPrint('[ArchiveUrlService] CDN URL rewritten to official endpoint:');
        debugPrint('  FROM: $url');
        debugPrint('  TO:   $fixedUrl');
      }
      
      return fixedUrl;
    }

    return url;
  }

  /// Check if URL is a CDN URL that needs CORS fixing
  ///
  /// CDN patterns:
  /// - dn*.archive.org (Canadian CDN nodes)
  /// - ia*.archive.org (US CDN nodes)
  /// - *.us.archive.org (Regional CDN)
  /// - *.ca.archive.org (Canadian regional CDN)
  bool _isCdnUrl(String url) {
    // Match CDN patterns
    final cdnPatterns = [
      RegExp(r'https?://dn\d+\..*?\.archive\.org'),      // dn720003.ca.archive.org
      RegExp(r'https?://ia\d+\..*?\.archive\.org'),      // ia801408.us.archive.org
      RegExp(r'https?://.*?\.us\.archive\.org'),         // *.us.archive.org
      RegExp(r'https?://.*?\.ca\.archive\.org'),         // *.ca.archive.org
    ];

    return cdnPatterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Batch fix multiple URLs (useful for file lists)
  ///
  /// Applies URL standardization to a list of URLs, all for the same identifier.
  /// More efficient than calling fixCorsUrl repeatedly.
  /// Works on ALL platforms to ensure consistency.
  List<String> fixCorsUrls(List<String> urls, String identifier) {
    if (urls.isEmpty) {
      return urls;
    }

    return urls.map((url) => fixCorsUrl(url, identifier)).toList();
  }

  // ============================================================================
  // URL VALIDATION & SANITIZATION
  // ============================================================================

  /// Validate that an identifier is safe for URL construction
  ///
  /// Archive.org identifiers should:
  /// - Not be empty
  /// - Not contain path separators (/, \)
  /// - Not contain URL-unsafe characters (?, #, &, etc.)
  /// - Be ASCII or properly encoded
  bool isValidIdentifier(String identifier) {
    if (identifier.trim().isEmpty) return false;
    
    // Check for path separators
    if (identifier.contains('/') || identifier.contains('\\')) return false;
    
    // Check for URL-unsafe characters
    if (identifier.contains(RegExp(r'[?#&=\s]'))) return false;
    
    return true;
  }

  /// Sanitize identifier for safe URL construction
  ///
  /// Removes leading/trailing whitespace and validates format.
  /// Throws ArgumentError if identifier is invalid.
  String _sanitizeIdentifier(String identifier) {
    final trimmed = identifier.trim();
    
    if (!isValidIdentifier(trimmed)) {
      throw ArgumentError('Invalid identifier: "$identifier"');
    }
    
    return trimmed;
  }

  /// Sanitize filename for safe URL construction
  ///
  /// Archive.org filenames may contain special characters.
  /// This method ensures proper URL encoding.
  String _sanitizeFilename(String filename) {
    // Don't double-encode if already encoded
    if (filename.contains('%')) {
      return filename;
    }
    
    // Encode special characters but preserve forward slashes (for paths)
    return Uri.encodeComponent(filename).replaceAll('%2F', '/');
  }

  // ============================================================================
  // URL PARSING & EXTRACTION
  // ============================================================================

  /// Extract identifier from an Archive.org URL
  ///
  /// Handles various URL formats:
  /// - https://archive.org/details/identifier
  /// - https://archive.org/metadata/identifier
  /// - https://archive.org/download/identifier/file.pdf
  /// - https://archive.org/services/img/identifier
  ///
  /// Returns null if identifier cannot be extracted.
  String? extractIdentifier(String url) {
    try {
      final uri = Uri.parse(url);
      
      if (!uri.host.endsWith('archive.org')) {
        return null;
      }

      final segments = uri.pathSegments;
      if (segments.isEmpty) return null;

      // Handle different endpoint patterns
      if (segments.length >= 2) {
        final endpoint = segments[0];
        final identifier = segments[1];
        
        if (['details', 'metadata', 'download'].contains(endpoint)) {
          return identifier;
        }
        
        if (endpoint == 'services' && segments.length >= 3 && segments[1] == 'img') {
          return segments[2];
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ArchiveUrlService] Failed to extract identifier from: $url');
      }
      return null;
    }
  }

  /// Extract filename from a download URL
  ///
  /// Example: https://archive.org/download/id/file.pdf -> file.pdf
  String? extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.length >= 3 && uri.pathSegments[0] == 'download') {
        return uri.pathSegments.sublist(2).join('/');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // DEBUGGING & MONITORING
  // ============================================================================

  /// Get comprehensive URL information for debugging
  ///
  /// Returns a map with all possible URLs for an identifier.
  Map<String, String> getDebugUrls(String identifier) {
    return {
      'metadata': getMetadataUrl(identifier),
      'details': getDetailsUrl(identifier),
      'directory': getDirectoryUrl(identifier),
      'thumbnail_web': getWebSafeThumbnailUrl(identifier),
      'thumbnail_native': getNativeThumbnailUrl(identifier),
    };
  }

  /// Print debug information about URL generation
  void debugPrintUrls(String identifier) {
    if (!kDebugMode) return;

    debugPrint('[ArchiveUrlService] URLs for $identifier:');
    final urls = getDebugUrls(identifier);
    urls.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }

  /// Get statistics about URL standardization (for monitoring)
  ///
  /// Note: This is stateless for now. Could be enhanced to track
  /// actual fix counts if needed for analytics.
  Map<String, dynamic> getStatistics() {
    return {
      'service': 'ArchiveUrlService',
      'url_standardization': 'active',
      'cdn_rewriting': 'enabled_all_platforms',
      'platform': kIsWeb ? 'web' : 'native',
    };
  }
}
