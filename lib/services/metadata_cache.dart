import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/cached_metadata.dart';
import '../models/archive_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline-first metadata caching with smart purge logic
///
/// Features:
/// - SQLite-based persistent storage
/// - ETag support for conditional GET requests
/// - LRU (Least Recently Used) eviction policy
/// - Pin/unpin archives to prevent auto-purge
/// - Cache size limits with automatic eviction
/// - Comprehensive metrics and statistics
/// - Batch operations for efficiency
/// - Debug logging for troubleshooting
class MetadataCache {
  static final MetadataCache _instance = MetadataCache._internal();
  factory MetadataCache() => _instance;
  MetadataCache._internal();

  /// Cache metrics for monitoring and optimization
  final CacheMetrics metrics = CacheMetrics();

  /// Shared preferences keys
  static const String _keyRetentionDays = 'cache_retention_days';
  static const String _keySyncFrequencyDays = 'cache_sync_frequency_days';
  static const String _keyMaxCacheSizeMB = 'cache_max_size_mb';
  static const String _keyAutoSync = 'cache_auto_sync';
  static const String _keyLastAutoPurge = 'cache_last_auto_purge';

  /// Default configuration values
  static const int defaultRetentionDays = 7;
  static const int defaultSyncFrequencyDays = 30; // Monthly
  static const int defaultMaxCacheSizeMB = 0; // 0 = unlimited

  /// Get database instance
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// Cache metadata for an archive (auto-cache on view)
  /// Cache metadata for an archive (auto-cache on view)
  ///
  /// Automatically enforces cache size limits by evicting least recently
  /// used entries when the cache exceeds the configured maximum size.
  ///
  /// Updates metrics (writes, evictions) and logs operations in debug mode.
  Future<void> cacheMetadata(
    ArchiveMetadata metadata, {
    bool isPinned = false,
    String? etag,
  }) async {
    final db = await _db;

    final cached = CachedMetadata.fromMetadata(
      metadata,
      isPinned: isPinned,
      etag: etag,
    );

    // Check cache size limits and evict if needed
    await _enforceSizeLimit();

    await db.insert(
      'cached_metadata',
      cached.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update metrics
    metrics.writes++;

    if (kDebugMode) {
      print('[MetadataCache] WRITE: ${metadata.identifier} '
          '(${cached.totalSize ~/ 1024} KB, pinned: $isPinned)');
    }
  }

  /// Get cached metadata by identifier
  ///
  /// Returns cached metadata if available, null otherwise.
  /// Updates metrics (hit/miss) and last accessed timestamp.
  Future<CachedMetadata?> getCachedMetadata(String identifier) async {
    final db = await _db;

    final maps = await db.query(
      'cached_metadata',
      where: 'identifier = ?',
      whereArgs: [identifier],
      limit: 1,
    );

    if (maps.isEmpty) {
      // Cache miss
      metrics.misses++;
      if (kDebugMode) {
        print('[MetadataCache] MISS: $identifier');
      }
      return null;
    }

    // Cache hit
    metrics.hits++;
    final cached = CachedMetadata.fromMap(maps.first);

    if (kDebugMode) {
      final ageHours = DateTime.now().difference(cached.cachedAt).inHours;
      print('[MetadataCache] HIT: $identifier (age: ${ageHours}h)');
    }

    // Update last accessed time
    await _updateLastAccessed(identifier);

    return cached;
  }

  /// Check if archive is cached
  Future<bool> isCached(String identifier) async {
    final db = await _db;

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cached_metadata WHERE identifier = ?',
        [identifier],
      ),
    );

    return (count ?? 0) > 0;
  }

  /// Get ETag for cached archive (for conditional GET requests)
  Future<String?> getETag(String identifier) async {
    final db = await _db;

    final maps = await db.query(
      'cached_metadata',
      columns: ['etag'],
      where: 'identifier = ?',
      whereArgs: [identifier],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['etag'] as String?;
  }

  /// Update ETag for cached archive (after successful fetch)
  Future<void> updateETag(String identifier, String? etag) async {
    final db = await _db;

    await db.update(
      'cached_metadata',
      {'etag': etag, 'last_synced': DateTime.now().millisecondsSinceEpoch},
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
  }

  /// Validate cache freshness using ETag
  /// Returns true if cache is still valid (304 Not Modified)
  /// Returns false if cache needs update (200 OK with new data)
  Future<bool> validateCacheWithETag(
    String identifier,
    String? serverETag,
  ) async {
    if (serverETag == null) return false;

    final cachedETag = await getETag(identifier);
    if (cachedETag == null) return false;

    // ETags match - cache is still valid
    if (cachedETag == serverETag) {
      // Update last_synced timestamp
      await updateETag(identifier, serverETag);
      return true;
    }

    return false;
  }

  /// Update last accessed timestamp (for LRU tracking)
  Future<void> _updateLastAccessed(String identifier) async {
    final db = await _db;

    await db.update(
      'cached_metadata',
      {'last_accessed': DateTime.now().millisecondsSinceEpoch},
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
  }

  /// Mark last accessed without returning metadata
  Future<void> markAccessed(String identifier) async {
    await _updateLastAccessed(identifier);
  }

  /// Pin an archive (prevents auto-purge)
  Future<void> pinArchive(String identifier) async {
    final db = await _db;

    await db.update(
      'cached_metadata',
      {'is_pinned': 1},
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
  }

  /// Unpin an archive (allows auto-purge)
  Future<void> unpinArchive(String identifier) async {
    final db = await _db;

    await db.update(
      'cached_metadata',
      {'is_pinned': 0},
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
  }

  /// Toggle pin status
  Future<void> togglePin(String identifier) async {
    final cached = await getCachedMetadata(identifier);
    if (cached == null) return;

    if (cached.isPinned) {
      await unpinArchive(identifier);
    } else {
      await pinArchive(identifier);
    }
  }

  /// Update metadata (sync from API)
  Future<void> syncMetadata(String identifier, ArchiveMetadata metadata) async {
    final db = await _db;

    final existing = await getCachedMetadata(identifier);
    if (existing == null) {
      // Cache if not already cached
      await cacheMetadata(metadata);
      return;
    }

    // Update with new metadata but preserve pin status
    final updated =
        CachedMetadata.fromMetadata(
          metadata,
          isPinned: existing.isPinned,
        ).copyWith(
          cachedAt: existing.cachedAt, // Preserve original cache time
          lastAccessed:
              existing.lastAccessed, // Will be updated by getCachedMetadata
          lastSynced: DateTime.now(),
        );

    await db.update(
      'cached_metadata',
      updated.toMap(),
      where: 'identifier = ?',
      whereArgs: [identifier],
    );
  }

  /// Enforce cache size limit by evicting LRU entries
  ///
  /// Checks if cache exceeds the configured maximum size and evicts
  /// least recently used (unpinned) entries until under the limit.
  ///
  /// Pinned archives are never evicted.
  Future<void> _enforceSizeLimit() async {
    final maxSizeMB = await getMaxCacheSizeMB();
    if (maxSizeMB <= 0) {
      // Unlimited cache size
      return;
    }

    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    final stats = await getCacheStats();

    if (stats.totalDataSize <= maxSizeBytes) {
      // Under limit, no eviction needed
      return;
    }

    final db = await _db;
    final bytesToFree = stats.totalDataSize - maxSizeBytes;

    if (kDebugMode) {
      print('[MetadataCache] Size limit exceeded: '
          '${stats.formattedDataSize} > $maxSizeMB MB, '
          'evicting ~${(bytesToFree / (1024 * 1024)).toStringAsFixed(1)} MB');
    }

    // Get unpinned entries sorted by last accessed (LRU)
    final candidates = await db.query(
      'cached_metadata',
      columns: ['identifier', 'total_size'],
      where: 'is_pinned = 0',
      orderBy: 'last_accessed ASC',
    );

    int freedBytes = 0;
    int evictionCount = 0;

    for (final entry in candidates) {
      if (freedBytes >= bytesToFree) break;

      final identifier = entry['identifier'] as String;
      final size = entry['total_size'] as int;

      await db.delete(
        'cached_metadata',
        where: 'identifier = ?',
        whereArgs: [identifier],
      );

      freedBytes += size;
      evictionCount++;
      metrics.evictions++;

      if (kDebugMode) {
        print('[MetadataCache] EVICT: $identifier (${size ~/ 1024} KB)');
      }
    }

    if (kDebugMode) {
      print('[MetadataCache] Evicted $evictionCount entries, '
          'freed ${(freedBytes / (1024 * 1024)).toStringAsFixed(1)} MB');
    }
  }

  /// Purge stale cache entries (LRU with exceptions)
  /// Does NOT purge:
  /// - Pinned archives
  /// - Archives in protectedIdentifiers list (downloaded archives, saved archives, etc.)
  /// - Archives in recent history (requires integration with history service)
  /// - Archives currently displayed in UI (not implemented yet)
  ///
  /// Note: The caller (typically ArchiveService) should automatically include
  /// downloaded archives in the protectedIdentifiers list.
  Future<int> purgeStaleCaches({
    List<String>? protectedIdentifiers,
    Duration? retentionPeriod,
  }) async {
    final db = await _db;
    final retention = retentionPeriod ?? await getRetentionPeriod();

    // Calculate cutoff time
    final cutoffTime = DateTime.now()
        .subtract(retention)
        .millisecondsSinceEpoch;

    // Build WHERE clause
    String whereClause = 'is_pinned = 0 AND last_accessed < ?';
    List<dynamic> whereArgs = [cutoffTime];

    // Add protected identifiers
    if (protectedIdentifiers != null && protectedIdentifiers.isNotEmpty) {
      final placeholders = List.filled(
        protectedIdentifiers.length,
        '?',
      ).join(', ');
      whereClause += ' AND identifier NOT IN ($placeholders)';
      whereArgs.addAll(protectedIdentifiers);
    }

    // Delete stale entries
    final count = await db.delete(
      'cached_metadata',
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Update last purge time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastAutoPurge,
      DateTime.now().millisecondsSinceEpoch,
    );

    return count;
  }

  /// Get all cached archives (for display/management)
  Future<List<CachedMetadata>> getAllCached({
    bool pinnedOnly = false,
    int? limit,
  }) async {
    final db = await _db;

    final maps = await db.query(
      'cached_metadata',
      where: pinnedOnly ? 'is_pinned = 1' : null,
      orderBy: 'last_accessed DESC',
      limit: limit,
    );

    return maps.map((map) => CachedMetadata.fromMap(map)).toList();
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    final db = await _db;

    // Total count
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_metadata'),
    );

    // Pinned count
    final pinnedCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cached_metadata WHERE is_pinned = 1',
      ),
    );

    // Total size
    final totalSize = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(total_size) FROM cached_metadata'),
    );

    // Database file size
    final dbSize = await DatabaseHelper.instance.getDatabaseSize();

    return CacheStats(
      totalArchives: totalCount ?? 0,
      pinnedArchives: pinnedCount ?? 0,
      totalDataSize: totalSize ?? 0,
      databaseSize: dbSize,
    );
  }

  /// Clear all cache (keeps settings)
  Future<void> clearAllCache() async {
    final db = await _db;
    await db.delete('cached_metadata');
  }

  /// Clear unpinned cache only
  Future<int> clearUnpinnedCache() async {
    final db = await _db;
    return await db.delete('cached_metadata', where: 'is_pinned = 0');
  }

  /// Delete specific cache entry
  ///
  /// Updates metrics (deletes) and logs operations in debug mode.
  Future<void> deleteCache(String identifier) async {
    final db = await _db;
    final deleted = await db.delete(
      'cached_metadata',
      where: 'identifier = ?',
      whereArgs: [identifier],
    );

    if (deleted > 0) {
      metrics.deletes++;

      if (kDebugMode) {
        print('[MetadataCache] DELETE: $identifier');
      }
    }
  }

  /// Get identifiers that need sync (stale metadata)
  Future<List<String>> getStaleIdentifiers({Duration? maxAge}) async {
    final db = await _db;
    final age = maxAge ?? await getSyncFrequency();
    final cutoffTime = DateTime.now().subtract(age).millisecondsSinceEpoch;

    final maps = await db.query(
      'cached_metadata',
      columns: ['identifier'],
      where: 'last_synced IS NULL OR last_synced < ?',
      whereArgs: [cutoffTime],
    );

    return maps.map((map) => map['identifier'] as String).toList();
  }

  /// Get retention period from settings
  Future<Duration> getRetentionPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt(_keyRetentionDays) ?? defaultRetentionDays;
    return Duration(days: days);
  }

  /// Set retention period
  Future<void> setRetentionPeriod(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRetentionDays, days);
  }

  /// Get sync frequency from settings
  Future<Duration> getSyncFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final days =
        prefs.getInt(_keySyncFrequencyDays) ?? defaultSyncFrequencyDays;
    return Duration(days: days);
  }

  /// Set sync frequency
  Future<void> setSyncFrequency(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySyncFrequencyDays, days);
  }

  /// Get max cache size limit (0 = unlimited)
  Future<int> getMaxCacheSizeMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxCacheSizeMB) ?? defaultMaxCacheSizeMB;
  }

  /// Set max cache size limit (0 = unlimited)
  Future<void> setMaxCacheSizeMB(int sizeMB) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxCacheSizeMB, sizeMB);
  }

  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  /// Set auto-sync enabled
  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, enabled);
  }

  /// Get time of last auto-purge
  Future<DateTime?> getLastAutoPurge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastAutoPurge);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Vacuum database to reclaim space
  Future<void> vacuum() async {
    await DatabaseHelper.instance.vacuum();
  }

  /// Cache multiple metadata items in a single transaction (batch operation)
  ///
  /// More efficient than calling cacheMetadata multiple times as it uses
  /// a single database transaction for all insertions.
  ///
  /// Returns the number of items successfully cached.
  Future<int> cacheMetadataBatch(
    List<ArchiveMetadata> metadataList, {
    bool isPinned = false,
  }) async {
    if (metadataList.isEmpty) return 0;

    final db = await _db;
    final batch = db.batch();

    for (final metadata in metadataList) {
      final cached = CachedMetadata.fromMetadata(
        metadata,
        isPinned: isPinned,
      );

      batch.insert(
        'cached_metadata',
        cached.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit(noResult: false);
    final successCount = results.length;

    // Update metrics
    metrics.writes += successCount;

    if (kDebugMode) {
      print('[MetadataCache] BATCH WRITE: $successCount items');
    }

    // Enforce size limits after batch operation
    await _enforceSizeLimit();

    return successCount;
  }

  /// Delete multiple cache entries in a single transaction (batch operation)
  ///
  /// More efficient than calling deleteCache multiple times as it uses
  /// a single database transaction for all deletions.
  ///
  /// Returns the number of items successfully deleted.
  Future<int> deleteCacheBatch(List<String> identifiers) async {
    if (identifiers.isEmpty) return 0;

    final db = await _db;
    final batch = db.batch();

    for (final identifier in identifiers) {
      batch.delete(
        'cached_metadata',
        where: 'identifier = ?',
        whereArgs: [identifier],
      );
    }

    final results = await batch.commit(noResult: false);
    final successCount = results.length;

    // Update metrics
    metrics.deletes += successCount;

    if (kDebugMode) {
      print('[MetadataCache] BATCH DELETE: $successCount items');
    }

    return successCount;
  }

  /// Dispose resources and cleanup
  ///
  /// Call this method when the cache is no longer needed to release resources.
  /// Currently logs final metrics in debug mode.
  ///
  /// Note: Database connections are managed by DatabaseHelper singleton and
  /// should not be closed here.
  void dispose() {
    if (kDebugMode) {
      print('[MetadataCache] Final metrics: $metrics');
    }
  }

  /// Get current metrics for monitoring
  ///
  /// Returns a snapshot of the current cache metrics including hit/miss rates,
  /// eviction counts, and total operations.
  CacheMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  ///
  /// Useful for testing or periodic monitoring. Does not affect cache data.
  void resetMetrics() {
    metrics.reset();
    if (kDebugMode) {
      print('[MetadataCache] Metrics reset');
    }
  }
}

/// Cache statistics
class CacheStats {
  final int totalArchives;
  final int pinnedArchives;
  final int totalDataSize;
  final int databaseSize;

  const CacheStats({
    required this.totalArchives,
    required this.pinnedArchives,
    required this.totalDataSize,
    required this.databaseSize,
  });

  int get unpinnedArchives => totalArchives - pinnedArchives;

  String get formattedDataSize => _formatBytes(totalDataSize);
  String get formattedDbSize => _formatBytes(databaseSize);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() {
    return 'CacheStats{archives: $totalArchives ($pinnedArchives pinned), '
        'data: $formattedDataSize, db: $formattedDbSize}';
  }
}

/// Cache performance metrics
///
/// Tracks cache behavior for monitoring and optimization:
/// - Hit/miss rates for effectiveness
/// - Eviction counts for size management
/// - Access patterns for optimization
class CacheMetrics {
  /// Cache hits (successful retrievals from cache)
  int hits = 0;

  /// Cache misses (not found in cache, need API call)
  int misses = 0;

  /// Number of evictions due to size limits
  int evictions = 0;

  /// Number of cache writes
  int writes = 0;

  /// Number of cache deletes
  int deletes = 0;

  /// Reset all metrics to zero
  void reset() {
    hits = 0;
    misses = 0;
    evictions = 0;
    writes = 0;
    deletes = 0;
  }

  /// Calculate hit rate (percentage of successful cache retrievals)
  double get hitRate {
    final total = hits + misses;
    return total > 0 ? (hits / total) * 100 : 0.0;
  }

  /// Calculate miss rate (percentage of cache misses)
  double get missRate {
    final total = hits + misses;
    return total > 0 ? (misses / total) * 100 : 0.0;
  }

  /// Total number of cache operations
  int get totalOperations => hits + misses + writes + deletes;

  @override
  String toString() {
    return 'CacheMetrics{'
        'hits: $hits, '
        'misses: $misses, '
        'evictions: $evictions, '
        'writes: $writes, '
        'deletes: $deletes, '
        'hitRate: ${hitRate.toStringAsFixed(1)}%, '
        'missRate: ${missRate.toStringAsFixed(1)}%'
        '}';
  }
}
