import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/internet_archive_constants.dart';

/// Centralized Archive.org URL Service
///
/// Provides comprehensive URL construction and CORS handling for all Archive.org
/// API interactions. This service ensures:
/// - Consistent URL formatting across the app
/// - Platform-aware URL construction (web vs native)
/// - CORS-compliant URLs for web platform (optional)
/// - CDN optimization with fallback support
/// - Archive.org best practices compliance
///
/// CDN vs Direct Access:
/// - **CDN (Default)**: Fast, distributed, Archive.org's preferred method
///   * Uses dn*.archive.org and ia*.archive.org servers
///   * Optimized for performance and bandwidth
///   * NO CORS headers (fails on web browsers)
/// - **Direct (/download/)**: Slower, but works on web
///   * Uses archive.org/download/ endpoint
///   * Has CORS headers for browser compatibility
///   * User-configurable fallback option
///
/// References:
/// - Archive.org API: https://archive.org/developers/
/// - CDN Policy: Archive.org prefers CDN usage for bandwidth efficiency
/// - CORS: Only /download/ endpoint guarantees CORS headers on web
class ArchiveUrlService {
  static final ArchiveUrlService _instance = ArchiveUrlService._internal();
  factory ArchiveUrlService() => _instance;
  ArchiveUrlService._internal();
  
  // Preference key for CDN usage
  static const String _prefKeyUseCdn = 'archive_url_use_cdn';
  
  // Cached preference value
  bool? _useCdnCached;
  
  /// Get CDN usage preference
  /// 
  /// Returns:
  /// - true: Use CDN URLs (default, faster, Archive.org's preferred method)
  /// - false: Use direct /download/ URLs (slower, but works on web)
  /// 
  /// On web platform, CDN URLs will cause CORS errors but are faster.
  /// On native platforms (mobile/desktop), CDN always works fine.
  Future<bool> getUseCdn() async {
    // Return cached value if available
    if (_useCdnCached != null) {
      return _useCdnCached!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    // Default to true (use CDN) - Archive.org's preferred method
    _useCdnCached = prefs.getBool(_prefKeyUseCdn) ?? true;
    return _useCdnCached!;
  }
  
  /// Set CDN usage preference
  /// 
  /// Parameters:
  /// - useCdn: true to use CDN (faster), false to use /download/ (web-safe)
  /// 
  /// Note: Changing this setting will affect all future URL generation.
  /// Existing cached images may still use old URLs.
  Future<void> setUseCdn(bool useCdn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyUseCdn, useCdn);
    _useCdnCached = useCdn;
    
    if (kDebugMode) {
      debugPrint('[ArchiveUrlService] CDN usage preference changed: $useCdn');
      debugPrint('  ${useCdn ? "Using CDN URLs (faster, Archive.org preferred)" : "Using /download/ URLs (slower, web-safe)"}');
    }
  }

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
  // THUMBNAIL URLS (CDN-AWARE WITH FALLBACK SUPPORT)
  // ============================================================================

  /// Get the best thumbnail URL for the given identifier
  ///
  /// Respects user preference for CDN vs direct access:
  /// - **CDN (Default)**: Fast, uses Archive.org's CDN infrastructure
  ///   * Fails on web browsers (CORS errors)
  ///   * Works perfectly on native platforms
  /// - **Direct**: Slower, but works on all platforms including web
  ///   * Uses /download/ endpoint with CORS headers
  /// 
  /// Note: This method is async now to check preferences
  Future<String> getThumbnailUrl(String identifier) async {
    final useCdn = await getUseCdn();
    
    // On web + CDN mode: Show warning in debug
    if (kIsWeb && useCdn && kDebugMode) {
      debugPrint('[ArchiveUrlService] WARNING: Using CDN on web (may cause CORS errors)');
      debugPrint('  To fix: Disable "Use CDN URLs" in Settings → API Settings');
    }
    
    if (useCdn) {
      return getNativeThumbnailUrl(identifier); // Uses CDN
    } else {
      return getWebSafeThumbnailUrl(identifier); // Uses /download/
    }
  }
  
  /// Get synchronous thumbnail URL (uses cached preference)
  ///
  /// Use this when you need immediate URL without async.
  /// Defaults to CDN (true) until preference loads.
  /// 
  /// First call starts background preference load with safe CDN default.
  String getThumbnailUrlSync(String identifier) {
    // If we don't have cached preference yet, load it in background
    if (_useCdnCached == null) {
      // Start loading preference in background (don't await)
      getUseCdn();
      // Default to CDN (Archive.org's preferred method) until preference loads
      _useCdnCached = true;
    }
    
    final useCdn = _useCdnCached!;
    
    if (useCdn) {
      return getNativeThumbnailUrl(identifier);
    } else {
      return getWebSafeThumbnailUrl(identifier);
    }
  }

  /// Get web-safe thumbnail URL (CORS-compliant, no CDN)
  ///
  /// Uses archive.org/services/img which properly handles thumbnails
  /// with CORS headers and automatic fallbacks.
  /// Slower than CDN but works on all platforms.
  ///
  /// Example: https://archive.org/services/img/identifier
  String getWebSafeThumbnailUrl(String identifier) {
    // Use /services/img endpoint which handles CORS better than /download/__ia_thumb.jpg
    // The /download/__ia_thumb.jpg path doesn't always exist for all archives
    return '${IAEndpoints.thumbnail}/${_sanitizeIdentifier(identifier)}';
  }

  /// Get native platform thumbnail URL (CDN, services/img endpoint)
  ///
  /// Faster endpoint using Archive.org's CDN infrastructure.
  /// May return CDN URLs (dn*.archive.org, ia*.archive.org).
  /// Will cause CORS errors on web browsers.
  /// 
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
