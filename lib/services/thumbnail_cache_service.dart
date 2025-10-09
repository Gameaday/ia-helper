import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../screens/api_intensity_settings_screen.dart';

/// Service for caching thumbnail images with LRU eviction
///
/// Features:
/// - Memory cache with LRU eviction (max 100MB)
/// - Disk cache persistence
/// - Network loading with graceful fallback
/// - Respects ApiIntensitySettings.loadThumbnails
/// - Cache metrics tracking
class ThumbnailCacheService {
  static final ThumbnailCacheService _instance =
      ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();

  /// Memory cache with LRU eviction
  final Map<String, Uint8List> _memoryCache = {};
  final List<String> _accessOrder = []; // For LRU tracking

  /// Cache configuration
  static const int maxMemoryCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int maxMemoryCacheItems = 200; // Max number of items
  int _currentMemoryCacheSize = 0;

  /// Cache metrics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _diskHits = 0;
  int _networkLoads = 0;
  int _failures = 0;

  /// Initialize cache and load settings
  Future<void> initialize() async {
    // Skip disk cache cleanup on web
    if (!kIsWeb) {
      await _cleanupOldCacheFiles();
    }
  }

  /// Get thumbnail image data
  ///
  /// Returns cached image from memory, disk, or network.
  /// Returns null if loading fails or thumbnails are disabled.
  Future<Uint8List?> getThumbnail(String url) async {
    // Check if thumbnails are enabled
    final settings = await ApiIntensitySettingsScreen.getSettings();
    if (!settings.loadThumbnails) {
      return null;
    }

    final cacheKey = _getCacheKey(url);

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      _hits++;
      _updateAccessOrder(cacheKey);
      return _memoryCache[cacheKey];
    }

    _misses++;

    // Check disk cache (skip on web platform)
    if (!kIsWeb) {
      final diskData = await _loadFromDisk(cacheKey);
      if (diskData != null) {
        _diskHits++;
        await _addToMemoryCache(cacheKey, diskData);
        return diskData;
      }
    }

    // Load from network
    try {
      final networkData = await _loadFromNetwork(url);
      if (networkData != null) {
        _networkLoads++;
        await _addToMemoryCache(cacheKey, networkData);
        // Save to disk only on native platforms
        if (!kIsWeb) {
          await _saveToDisk(cacheKey, networkData);
        }
        return networkData;
      }
    } catch (e) {
      _failures++;
      debugPrint('Failed to load thumbnail from network: $e');
    }

    return null;
  }

  /// Preload thumbnails for a list of URLs
  ///
  /// Useful for preloading search results.
  Future<void> preloadThumbnails(List<String> urls) async {
    final settings = await ApiIntensitySettingsScreen.getSettings();
    if (!settings.loadThumbnails || !settings.preloadMetadata) {
      return;
    }

    // Limit concurrent requests
    final batchSize = settings.maxConcurrentRequests;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      await Future.wait(
        batch.map((url) => getThumbnail(url)),
        eagerError: false,
      );
    }
  }

  /// Add image to memory cache with LRU eviction
  Future<void> _addToMemoryCache(String key, Uint8List data) async {
    final dataSize = data.lengthInBytes;

    // Evict items if necessary
    while (_memoryCache.length >= maxMemoryCacheItems ||
        _currentMemoryCacheSize + dataSize > maxMemoryCacheSizeBytes) {
      if (_accessOrder.isEmpty) break;

      final evictKey = _accessOrder.removeAt(0);
      final evictedData = _memoryCache.remove(evictKey);
      if (evictedData != null) {
        _currentMemoryCacheSize -= evictedData.lengthInBytes;
        _evictions++;
      }
    }

    // Add new item
    _memoryCache[key] = data;
    _accessOrder.add(key);
    _currentMemoryCacheSize += dataSize;
  }

  /// Update access order for LRU
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Load image from disk cache (native platforms only)
  Future<Uint8List?> _loadFromDisk(String key) async {
    if (kIsWeb) return null; // Skip on web
    
    try {
      final file = await _getCacheFile(key);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Failed to load from disk: $e');
      }
    }
    return null;
  }

  /// Save image to disk cache (native platforms only)
  Future<void> _saveToDisk(String key, Uint8List data) async {
    if (kIsWeb) return; // Skip on web
    
    try {
      final file = await _getCacheFile(key);
      await file.writeAsBytes(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Failed to save to disk: $e');
      }
    }
  }

  /// Load image from network
  ///
  /// On web, CORS issues may prevent loading some Archive.org thumbnails.
  /// Falls back gracefully on error.
  Future<Uint8List?> _loadFromNetwork(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (kDebugMode) {
        debugPrint(
            '[ThumbnailCache] HTTP ${response.statusCode} for: $url');
      }
    } catch (e) {
      // On web, CORS errors are expected for some Archive.org thumbnails
      // Log only in debug mode to avoid console spam
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Network error for $url: $e');
      }
    }
    return null;
  }

  /// Get cache file for a key (native platforms only)
  Future<File> _getCacheFile(String key) async {
    if (kIsWeb) {
      throw UnsupportedError('File system not supported on web');
    }
    
    final directory = await getApplicationCacheDirectory();
    final cacheDir = Directory('${directory.path}/thumbnails');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$key.jpg');
  }

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Clean up old cache files (older than 30 days) - native platforms only
  Future<void> _cleanupOldCacheFiles() async {
    if (kIsWeb) return; // Skip on web
    
    try {
      final directory = await getApplicationCacheDirectory();
      final cacheDir = Directory('${directory.path}/thumbnails');

      if (!await cacheDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final maxAge = const Duration(days: 30);

      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          if (age > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Cleanup failed: $e');
      }
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _accessOrder.clear();
    _currentMemoryCacheSize = 0;

    // Clear disk cache (native platforms only)
    if (!kIsWeb) {
      try {
        final directory = await getApplicationCacheDirectory();
        final cacheDir = Directory('${directory.path}/thumbnails');

        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ThumbnailCache] Failed to clear disk cache: $e');
        }
      }
    }

    // Reset metrics
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _diskHits = 0;
    _networkLoads = 0;
    _failures = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? _hits / totalRequests : 0.0;

    return {
      'memoryItems': _memoryCache.length,
      'memorySizeMB': (_currentMemoryCacheSize / (1024 * 1024)).toStringAsFixed(
        2,
      ),
      'hits': _hits,
      'misses': _misses,
      'diskHits': _diskHits,
      'networkLoads': _networkLoads,
      'evictions': _evictions,
      'failures': _failures,
      'hitRate': (hitRate * 100).toStringAsFixed(1),
      'totalRequests': totalRequests,
    };
  }

  /// Get current cache size in bytes
  int get currentCacheSize => _currentMemoryCacheSize;

  /// Get number of cached items
  int get cachedItemCount => _memoryCache.length;

  /// Get cache hit rate
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }

  /// Check if URL is cached in memory
  bool isCachedInMemory(String url) {
    final key = _getCacheKey(url);
    return _memoryCache.containsKey(key);
  }

  /// Check if URL is cached on disk (native platforms only)
  Future<bool> isCachedOnDisk(String url) async {
    if (kIsWeb) return false;
    
    try {
      final key = _getCacheKey(url);
      final file = await _getCacheFile(key);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Remove specific URL from cache
  Future<void> removeThumbnail(String url) async {
    final key = _getCacheKey(url);

    // Remove from memory cache
    final data = _memoryCache.remove(key);
    if (data != null) {
      _currentMemoryCacheSize -= data.lengthInBytes;
      _accessOrder.remove(key);
    }

    // Remove from disk cache (native platforms only)
    if (!kIsWeb) {
      try {
        final file = await _getCacheFile(key);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ThumbnailCache] Failed to remove from disk: $e');
        }
      }
    }
  }

  /// Get disk cache size (native platforms only)
  Future<int> getDiskCacheSize() async {
    if (kIsWeb) return 0;
    
    try {
      final directory = await getApplicationCacheDirectory();
      final cacheDir = Directory('${directory.path}/thumbnails');

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size.toInt();
        }
      }

      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Failed to calculate disk cache size: $e');
      }
      return 0;
    }
  }

  /// Get disk cache item count (native platforms only)
  Future<int> getDiskCacheItemCount() async {
    if (kIsWeb) return 0;
    
    try {
      final directory = await getApplicationCacheDirectory();
      final cacheDir = Directory('${directory.path}/thumbnails');

      if (!await cacheDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          count++;
        }
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ThumbnailCache] Failed to count disk cache items: $e');
      }
      return 0;
    }
  }
}
