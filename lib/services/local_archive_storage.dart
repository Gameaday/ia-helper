import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_archive.dart';

/// Sort options for downloaded archives
enum ArchiveSortOption {
  /// Sort by last accessed date (most recent first)
  recentFirst,

  /// Sort by download date (newest first)
  newestFirst,

  /// Sort by download date (oldest first)
  oldestFirst,

  /// Sort by title (A-Z)
  titleAsc,

  /// Sort by title (Z-A)
  titleDesc,

  /// Sort by total size (largest first)
  sizeLargest,

  /// Sort by total size (smallest first)
  sizeSmallest,

  /// Sort by completion percentage (most complete first)
  completionDesc,

  /// Sort by completion percentage (least complete first)
  completionAsc,
}

/// Service for managing locally downloaded archives
///
/// Features:
/// - Persistent storage via SharedPreferences
/// - Version management for data migration
/// - Tag and notes support
/// - Search and filter capabilities
/// - Multiple sorting options
/// - Batch operations for efficiency
/// - Comprehensive metrics tracking
/// - Storage size limits with cleanup
/// - Debounced saves for performance
/// - Export/import functionality
class LocalArchiveStorage extends ChangeNotifier {
  static const String _storageKey = 'downloaded_archives';
  static const String _versionKey = 'archive_storage_version';
  static const int _currentVersion = 1;
  static const int _maxArchives = 1000; // Prevent unbounded growth

  SharedPreferences? _prefs;
  Map<String, DownloadedArchive> _archives = {};
  bool _isInitialized = false;

  /// Metrics for monitoring
  final StorageMetrics metrics = StorageMetrics();

  /// Debounced save management
  Timer? _saveTimer;
  bool _needsSave = false;

  /// Get all downloaded archives
  Map<String, DownloadedArchive> get archives => Map.unmodifiable(_archives);

  /// Get archives sorted by last accessed (most recent first)
  List<DownloadedArchive> get recentArchives {
    final list = _archives.values.toList();
    list.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    return list;
  }

  /// Get archives sorted by download date (most recent first)
  List<DownloadedArchive> get newestArchives {
    final list = _archives.values.toList();
    list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return list;
  }

  /// Get total number of archived items
  int get archiveCount => _archives.length;

  /// Get total number of downloaded files across all archives
  int get totalDownloadedFiles {
    return _archives.values.fold(
      0,
      (sum, archive) => sum + archive.downloadedFiles,
    );
  }

  /// Get total bytes downloaded across all archives
  int get totalDownloadedBytes {
    return _archives.values.fold(
      0,
      (sum, archive) => sum + archive.downloadedBytes,
    );
  }

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadArchives();
      _isInitialized = true;
      debugPrint(
        'LocalArchiveStorage initialized: ${_archives.length} archives',
      );
    } catch (e) {
      debugPrint('Failed to initialize LocalArchiveStorage: $e');
      rethrow;
    }
  }

  /// Load archives from persistent storage
  Future<void> _loadArchives() async {
    try {
      final version = _prefs!.getInt(_versionKey) ?? 0;

      if (version != _currentVersion) {
        debugPrint('Archive storage version mismatch, clearing old data');
        await _clearStorage();
        await _prefs!.setInt(_versionKey, _currentVersion);
        return;
      }

      final jsonString = _prefs!.getString(_storageKey);
      if (jsonString == null) return;

      final Map<String, dynamic> json = jsonDecode(jsonString);
      _archives = json.map(
        (key, value) => MapEntry(
          key,
          DownloadedArchive.fromJson(value as Map<String, dynamic>),
        ),
      );

      metrics.loads++;
      debugPrint('Loaded ${_archives.length} archives from storage');
    } catch (e) {
      debugPrint('Error loading archives: $e');
      _archives = {};
    }
  }

  /// Save archives to persistent storage
  Future<void> _saveArchives() async {
    if (!_isInitialized) return;

    try {
      final json = _archives.map((key, value) => MapEntry(key, value.toJson()));
      final jsonString = jsonEncode(json);
      await _prefs!.setString(_storageKey, jsonString);
      debugPrint('Saved ${_archives.length} archives to storage');
    } catch (e) {
      debugPrint('Error saving archives: $e');
    }
  }

  /// Add or update an archive
  ///
  /// Updates metrics and schedules a debounced save operation.
  Future<void> saveArchive(DownloadedArchive archive) async {
    _archives[archive.identifier] = archive;
    metrics.saves++;
    _scheduleSave();
    notifyListeners();

    if (kDebugMode) {
      print('[LocalArchiveStorage] Save: ${archive.identifier}');
    }
  }

  /// Get a specific archive by identifier
  DownloadedArchive? getArchive(String identifier) {
    return _archives[identifier];
  }

  /// Check if an archive exists in local storage
  bool hasArchive(String identifier) {
    return _archives.containsKey(identifier);
  }

  /// Remove an archive from storage
  ///
  /// Updates metrics and schedules a debounced save operation.
  Future<void> removeArchive(String identifier) async {
    if (_archives.remove(identifier) != null) {
      metrics.removes++;
      _scheduleSave();
      notifyListeners();

      if (kDebugMode) {
        print('[LocalArchiveStorage] Remove: $identifier');
      }
    }
  }

  /// Update an archive's access time
  ///
  /// Schedules a debounced save operation.
  Future<void> markArchiveAccessed(String identifier) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.markAccessed();
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Update a specific file's download state
  ///
  /// Schedules a debounced save operation.
  Future<void> updateFileState(
    String identifier,
    String filename,
    bool isDownloaded,
  ) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.updateFileState(filename, isDownloaded);
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Add tags to an archive
  ///
  /// Schedules a debounced save operation.
  Future<void> addTags(String identifier, List<String> tags) async {
    final archive = _archives[identifier];
    if (archive != null) {
      final currentTags = Set<String>.from(archive.tags);
      currentTags.addAll(tags);
      _archives[identifier] = archive.copyWith(tags: currentTags.toList());
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Remove tags from an archive
  ///
  /// Schedules a debounced save operation.
  Future<void> removeTags(String identifier, List<String> tags) async {
    final archive = _archives[identifier];
    if (archive != null) {
      final currentTags = Set<String>.from(archive.tags);
      currentTags.removeAll(tags);
      _archives[identifier] = archive.copyWith(tags: currentTags.toList());
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Update archive notes
  ///
  /// Schedules a debounced save operation.
  Future<void> updateNotes(String identifier, String? notes) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.copyWith(notes: notes);
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Get archives by tag
  List<DownloadedArchive> getArchivesByTag(String tag) {
    return _archives.values
        .where((archive) => archive.tags.contains(tag))
        .toList();
  }

  /// Get all unique tags across archives
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final archive in _archives.values) {
      tags.addAll(archive.tags);
    }
    return tags;
  }

  /// Search archives by title, creator, or identifier
  List<DownloadedArchive> searchArchives(String query) {
    metrics.searches++;
    final lowerQuery = query.toLowerCase();
    return _archives.values.where((archive) {
      return archive.identifier.toLowerCase().contains(lowerQuery) ||
          (archive.metadata.title?.toLowerCase().contains(lowerQuery) ??
              false) ||
          (archive.metadata.creator?.toLowerCase().contains(lowerQuery) ??
              false);
    }).toList();
  }

  /// Get statistics about local archives
  Map<String, dynamic> getStatistics() {
    int totalFiles = 0;
    int downloadedFiles = 0;
    int totalBytes = 0;
    int downloadedBytes = 0;
    int completeArchives = 0;

    for (final archive in _archives.values) {
      totalFiles += archive.totalFiles;
      downloadedFiles += archive.downloadedFiles;
      totalBytes += archive.totalBytes;
      downloadedBytes += archive.downloadedBytes;
      if (archive.isComplete) completeArchives++;
    }

    return {
      'archiveCount': _archives.length,
      'totalFiles': totalFiles,
      'downloadedFiles': downloadedFiles,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'completeArchives': completeArchives,
      'completionPercentage': totalFiles > 0
          ? downloadedFiles / totalFiles
          : 0.0,
    };
  }

  /// Clear all stored archives (use with caution!)
  Future<void> _clearStorage() async {
    _archives.clear();
    await _prefs!.remove(_storageKey);
    notifyListeners();
    debugPrint('Cleared all archive storage');
  }

  /// Export archives to JSON for backup
  String exportToJson() {
    final json = _archives.map((key, value) => MapEntry(key, value.toJson()));
    return jsonEncode(json);
  }

  /// Import archives from JSON backup
  Future<void> importFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final imported = json.map(
        (key, value) => MapEntry(
          key,
          DownloadedArchive.fromJson(value as Map<String, dynamic>),
        ),
      );

      _archives.addAll(imported);
      await _saveArchives();
      notifyListeners();
      debugPrint('Imported ${imported.length} archives');
    } catch (e) {
      debugPrint('Error importing archives: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_needsSave) {
      _saveArchives();
    }

    if (kDebugMode) {
      print('[LocalArchiveStorage] Final metrics: $metrics');
    }

    super.dispose();
  }

  /// Schedule a debounced save operation
  ///
  /// Saves are debounced by 2 seconds to avoid excessive writes.
  void _scheduleSave() {
    _needsSave = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_needsSave) {
        _saveArchives();
        _needsSave = false;
      }
    });
  }

  /// Get sorted archives with multiple sorting options
  List<DownloadedArchive> getSorted(ArchiveSortOption option) {
    final list = _archives.values.toList();

    switch (option) {
      case ArchiveSortOption.recentFirst:
        list.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
        break;
      case ArchiveSortOption.newestFirst:
        list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
        break;
      case ArchiveSortOption.oldestFirst:
        list.sort((a, b) => a.downloadedAt.compareTo(b.downloadedAt));
        break;
      case ArchiveSortOption.titleAsc:
        list.sort((a, b) {
          final aTitle = a.metadata.title ?? '';
          final bTitle = b.metadata.title ?? '';
          return aTitle.compareTo(bTitle);
        });
        break;
      case ArchiveSortOption.titleDesc:
        list.sort((a, b) {
          final aTitle = a.metadata.title ?? '';
          final bTitle = b.metadata.title ?? '';
          return bTitle.compareTo(aTitle);
        });
        break;
      case ArchiveSortOption.sizeLargest:
        list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
        break;
      case ArchiveSortOption.sizeSmallest:
        list.sort((a, b) => a.totalBytes.compareTo(b.totalBytes));
        break;
      case ArchiveSortOption.completionDesc:
        list.sort((a, b) {
          final aCompletion = a.downloadedFiles / a.totalFiles;
          final bCompletion = b.downloadedFiles / b.totalFiles;
          return bCompletion.compareTo(aCompletion);
        });
        break;
      case ArchiveSortOption.completionAsc:
        list.sort((a, b) {
          final aCompletion = a.downloadedFiles / a.totalFiles;
          final bCompletion = b.downloadedFiles / b.totalFiles;
          return aCompletion.compareTo(bCompletion);
        });
        break;
    }

    return list;
  }

  /// Filter archives by completion status
  List<DownloadedArchive> filterByCompletion({
    bool? isComplete,
    double? minCompletion,
    double? maxCompletion,
  }) {
    metrics.filters++;

    return _archives.values.where((archive) {
      if (isComplete != null && archive.isComplete != isComplete) {
        return false;
      }

      final completion = archive.downloadedFiles / archive.totalFiles;

      if (minCompletion != null && completion < minCompletion) {
        return false;
      }

      if (maxCompletion != null && completion > maxCompletion) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Filter archives by date range
  List<DownloadedArchive> filterByDateRange(DateTime start, DateTime end) {
    metrics.filters++;

    return _archives.values.where((archive) {
      return archive.downloadedAt.isAfter(start) &&
          archive.downloadedAt.isBefore(end);
    }).toList();
  }

  /// Remove archives older than the specified duration
  ///
  /// Returns the number of archives removed.
  Future<int> removeOlderThan(Duration duration) async {
    final cutoff = DateTime.now().subtract(duration);
    final toRemove = <String>[];

    for (final entry in _archives.entries) {
      if (entry.value.downloadedAt.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    if (toRemove.isNotEmpty) {
      for (final id in toRemove) {
        _archives.remove(id);
      }

      metrics.removes += toRemove.length;
      await _saveArchives();
      notifyListeners();

      if (kDebugMode) {
        print('[LocalArchiveStorage] Removed ${toRemove.length} archives '
            'older than ${duration.inDays} days');
      }
    }

    return toRemove.length;
  }

  /// Batch save multiple archives
  ///
  /// More efficient than calling saveArchive multiple times.
  /// Returns the number of archives saved.
  Future<int> saveBatch(List<DownloadedArchive> archives) async {
    if (archives.isEmpty) return 0;

    for (final archive in archives) {
      _archives[archive.identifier] = archive;
    }

    metrics.saves += archives.length;
    await _saveArchives();
    notifyListeners();

    if (kDebugMode) {
      print('[LocalArchiveStorage] Batch save: ${archives.length} archives');
    }

    return archives.length;
  }

  /// Batch remove multiple archives
  ///
  /// More efficient than calling removeArchive multiple times.
  /// Returns the number of archives removed.
  Future<int> removeBatch(List<String> identifiers) async {
    if (identifiers.isEmpty) return 0;

    final removed = <String>[];
    for (final id in identifiers) {
      if (_archives.remove(id) != null) {
        removed.add(id);
      }
    }

    if (removed.isNotEmpty) {
      metrics.removes += removed.length;
      await _saveArchives();
      notifyListeners();

      if (kDebugMode) {
        print('[LocalArchiveStorage] Batch remove: ${removed.length} archives');
      }
    }

    return removed.length;
  }

  /// Enforce storage size limit by removing oldest archives
  ///
  /// Keeps the most recently accessed archives up to _maxArchives limit.
  Future<int> enforceStorageLimit() async {
    if (_archives.length <= _maxArchives) {
      return 0;
    }

    final sorted = getSorted(ArchiveSortOption.recentFirst);
    final toRemove = sorted.skip(_maxArchives).map((a) => a.identifier).toList();

    return await removeBatch(toRemove);
  }

  /// Get formatted statistics
  StorageStatistics getFormattedStatistics() {
    int totalFiles = 0;
    int downloadedFiles = 0;
    int totalBytes = 0;
    int downloadedBytes = 0;
    int completeArchives = 0;

    for (final archive in _archives.values) {
      totalFiles += archive.totalFiles;
      downloadedFiles += archive.downloadedFiles;
      totalBytes += archive.totalBytes;
      downloadedBytes += archive.downloadedBytes;
      if (archive.isComplete) completeArchives++;
    }

    return StorageStatistics(
      archiveCount: _archives.length,
      totalFiles: totalFiles,
      downloadedFiles: downloadedFiles,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      completeArchives: completeArchives,
    );
  }

  /// Get current metrics for monitoring
  StorageMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  void resetMetrics() {
    metrics.reset();
    if (kDebugMode) {
      print('[LocalArchiveStorage] Metrics reset');
    }
  }
}

/// Storage statistics with formatted output
class StorageStatistics {
  final int archiveCount;
  final int totalFiles;
  final int downloadedFiles;
  final int totalBytes;
  final int downloadedBytes;
  final int completeArchives;

  const StorageStatistics({
    required this.archiveCount,
    required this.totalFiles,
    required this.downloadedFiles,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.completeArchives,
  });

  int get incompleteArchives => archiveCount - completeArchives;
  double get completionPercentage =>
      totalFiles > 0 ? (downloadedFiles / totalFiles) * 100 : 0.0;

  String get formattedTotalBytes => _formatBytes(totalBytes);
  String get formattedDownloadedBytes => _formatBytes(downloadedBytes);

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
    return 'StorageStatistics{'
        'archives: $archiveCount ($completeArchives complete), '
        'files: $downloadedFiles/$totalFiles, '
        'size: $formattedDownloadedBytes/$formattedTotalBytes, '
        'completion: ${completionPercentage.toStringAsFixed(1)}%'
        '}';
  }
}

/// Storage service performance metrics
///
/// Tracks operations for monitoring and optimization:
/// - Saves/removes for activity tracking
/// - Searches/filters for usage patterns
/// - Loads for initialization tracking
class StorageMetrics {
  /// Number of archives saved
  int saves = 0;

  /// Number of archives removed
  int removes = 0;

  /// Number of search operations
  int searches = 0;

  /// Number of filter operations
  int filters = 0;

  /// Number of load operations
  int loads = 0;

  /// Reset all metrics to zero
  void reset() {
    saves = 0;
    removes = 0;
    searches = 0;
    filters = 0;
    loads = 0;
  }

  /// Total number of operations
  int get totalOperations => saves + removes + searches + filters + loads;

  @override
  String toString() {
    return 'StorageMetrics{'
        'saves: $saves, '
        'removes: $removes, '
        'searches: $searches, '
        'filters: $filters, '
        'loads: $loads, '
        'total: $totalOperations'
        '}';
  }
}
