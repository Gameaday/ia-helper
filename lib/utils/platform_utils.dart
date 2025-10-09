import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform-specific utilities for handling web vs native differences
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if file system operations are supported
  static bool get supportsFileSystem => !kIsWeb;

  /// Check if native path_provider is available
  static bool get supportsPathProvider => !kIsWeb;

  /// Check if CORS-restricted resources can be loaded
  /// 
  /// On web, some resources may be blocked by CORS policies.
  /// This helper indicates when we should use fallback strategies.
  static bool get hasCorsRestrictions => kIsWeb;

  /// Get appropriate cache strategy for current platform
  static CacheStrategy get recommendedCacheStrategy =>
      kIsWeb ? CacheStrategy.memoryOnly : CacheStrategy.memoryAndDisk;
}

/// Cache storage strategies for different platforms
enum CacheStrategy {
  /// Memory-only caching (web-safe)
  memoryOnly,

  /// Memory + disk caching (native platforms)
  memoryAndDisk,
}
