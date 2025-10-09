import 'package:flutter/foundation.dart';

/// Thumbnail URL service for Archive.org
///
/// Provides platform-aware thumbnail URLs:
/// - Native: Uses standard /services/img/ endpoint (no CORS issues)
/// - Web: Tries CORS-friendly alternatives before fallback
///
/// Archive.org thumbnail endpoints (in order of preference for web):
/// 1. /download/{id}/__ia_thumb.jpg - CORS-enabled, item-level
/// 2. /services/img/{id} - Standard endpoint (CORS blocked on some items)
/// 3. Fallback to placeholder if both fail
class ThumbnailUrlService {
  static final ThumbnailUrlService _instance = ThumbnailUrlService._internal();
  factory ThumbnailUrlService() => _instance;
  ThumbnailUrlService._internal();

  /// Get the best thumbnail URL for the given identifier
  ///
  /// On web, returns CORS-friendly alternatives.
  /// On native, returns standard endpoint.
  String getThumbnailUrl(String identifier) {
    if (kIsWeb) {
      return _getWebThumbnailUrl(identifier);
    }
    return _getNativeThumbnailUrl(identifier);
  }

  /// Get thumbnail URLs to try in order (web only)
  ///
  /// Returns multiple URLs to attempt, in order of likelihood to work:
  /// 1. Item download URL (most likely to have CORS)
  /// 2. Standard services/img URL (may work for some items)
  List<String> getWebThumbnailUrls(String identifier) {
    return [
      'https://archive.org/download/$identifier/__ia_thumb.jpg',
      'https://archive.org/services/img/$identifier',
    ];
  }

  /// Native platform thumbnail URL (standard endpoint)
  String _getNativeThumbnailUrl(String identifier) {
    return 'https://archive.org/services/img/$identifier';
  }

  /// Web platform thumbnail URL (CORS-friendly alternative)
  ///
  /// Try the download endpoint first, as it's more likely to have CORS headers.
  /// Falls back to services/img if needed.
  String _getWebThumbnailUrl(String identifier) {
    // Primary: Try item download path (more likely to have CORS)
    return 'https://archive.org/download/$identifier/__ia_thumb.jpg';
  }

  /// Check if a URL is a thumbnail URL that needs CORS handling
  bool needsCorsHandling(String url) {
    if (!kIsWeb) return false;
    return url.contains('archive.org');
  }

  /// Get fallback thumbnail URL (data URI for placeholder)
  ///
  /// Returns a small base64-encoded placeholder image that works everywhere.
  /// This is used when all thumbnail loading attempts fail on web.
  String get fallbackThumbnail {
    // 1x1 transparent PNG as data URI (works everywhere, no CORS)
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  }

  /// Generate a colored placeholder for the given identifier
  ///
  /// Uses the identifier hash to generate a consistent color.
  /// Returns a data URI with a solid color image.
  String getColorPlaceholder(String identifier, {int size = 200}) {
    // Generate a color from the identifier
    final hash = identifier.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);

    // Create SVG placeholder with identifier's color
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size">
  <rect width="$size" height="$size" fill="rgb($r,$g,$b)" opacity="0.3"/>
  <text x="50%" y="50%" font-family="sans-serif" font-size="${size * 0.4}" 
        fill="rgb($r,$g,$b)" text-anchor="middle" dominant-baseline="middle">
    📦
  </text>
</svg>
''';

    // Encode as data URI
    final encoded = Uri.encodeComponent(svg);
    return 'data:image/svg+xml,$encoded';
  }

  /// Debug: Print available thumbnail endpoints for an identifier
  void debugPrintEndpoints(String identifier) {
    if (!kDebugMode) return;

    debugPrint('[ThumbnailUrl] Available endpoints for $identifier:');
    debugPrint('  1. ${_getWebThumbnailUrl(identifier)} (CORS-friendly)');
    debugPrint('  2. ${_getNativeThumbnailUrl(identifier)} (standard)');
    debugPrint('  3. ${getColorPlaceholder(identifier)} (placeholder)');
  }
}
