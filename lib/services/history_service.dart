import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sort options for history entries
enum HistorySortOption {
  /// Sort by visited date (most recent first)
  recentFirst,

  /// Sort by visited date (oldest first)
  oldestFirst,

  /// Sort by title (A-Z)
  titleAsc,

  /// Sort by title (Z-A)
  titleDesc,

  /// Sort by creator (A-Z)
  creatorAsc,

  /// Sort by creator (Z-A)
  creatorDesc,

  /// Sort by total size (largest first)
  sizeLargest,

  /// Sort by total size (smallest first)
  sizeSmallest,
}

/// Represents a visited archive in history
class HistoryEntry {
  final String identifier;
  final String title;
  final String? description;
  final String? creator;
  final int totalFiles;
  final int totalSize;
  final DateTime visitedAt;

  HistoryEntry({
    required this.identifier,
    required this.title,
    this.description,
    this.creator,
    required this.totalFiles,
    required this.totalSize,
    required this.visitedAt,
  });

  /// Create from JSON
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      identifier: json['identifier'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      creator: json['creator'] as String?,
      totalFiles: json['totalFiles'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'title': title,
      'description': description,
      'creator': creator,
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'visitedAt': visitedAt.toIso8601String(),
    };
  }

  /// Format the visited date as a relative time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(visitedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}

/// Service for managing archive visit history
///
/// Features:
/// - Persistent storage via SharedPreferences
/// - Automatic deduplication (updates existing entries)
/// - Size limits to prevent unbounded growth
/// - Search and filter capabilities
/// - Multiple sorting options
/// - Batch operations for efficiency
/// - Comprehensive metrics tracking
/// - Date-based cleanup
/// - Debounced saves for performance
class HistoryService extends ChangeNotifier {
  final List<HistoryEntry> _history = [];
  static const int _maxHistorySize = 100;
  static const String _historyKey = 'archive_history';
  
  /// Metrics for monitoring
  final HistoryMetrics metrics = HistoryMetrics();

  bool _isLoaded = false;
  Timer? _saveTimer;
  bool _needsSave = false;

  /// Get all history entries
  List<HistoryEntry> get history => List.unmodifiable(_history);

  /// Check if history has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Add an archive to history (or update if already exists)
  ///
  /// Updates metrics and schedules a debounced save operation.
  void addToHistory(HistoryEntry entry) {
    // Remove existing entry with same identifier if exists
    _history.removeWhere((e) => e.identifier == entry.identifier);

    // Add to beginning (most recent first)
    _history.insert(0, entry);

    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeRange(_maxHistorySize, _history.length);
    }

    metrics.adds++;
    notifyListeners();
    _scheduleSave();

    if (kDebugMode) {
      print('[HistoryService] Add: ${entry.identifier}');
    }
  }

  /// Remove an entry from history
  ///
  /// Updates metrics and schedules a debounced save operation.
  void removeFromHistory(String identifier) {
    final initialSize = _history.length;
    _history.removeWhere((e) => e.identifier == identifier);
    
    if (_history.length < initialSize) {
      metrics.removes++;
      notifyListeners();
      _scheduleSave();

      if (kDebugMode) {
        print('[HistoryService] Remove: $identifier');
      }
    }
  }

  /// Clear all history
  ///
  /// Updates metrics and schedules a debounced save operation.
  void clearHistory() {
    _history.clear();
    metrics.clears++;
    notifyListeners();
    _scheduleSave();

    if (kDebugMode) {
      print('[HistoryService] Clear: all history removed');
    }
  }

  /// Save history to persistent storage
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _history.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_historyKey, jsonString);

      if (kDebugMode) {
        print('History saved: ${_history.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving history: $e');
      }
    }
  }

  /// Load history from persistent storage
  Future<void> loadHistory() async {
    if (_isLoaded) {
      return; // Already loaded
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _history.clear();
        _history.addAll(
          jsonList.map(
            (json) => HistoryEntry.fromJson(json as Map<String, dynamic>),
          ),
        );

        if (kDebugMode) {
          print('History loaded: ${_history.length} entries');
        }
      } else {
        if (kDebugMode) {
          print('No saved history found');
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading history: $e');
      }
      _isLoaded =
          true; // Mark as loaded even on error to prevent repeated attempts
    }
  }

  /// Search history entries by keyword
  ///
  /// Searches in title, description, creator, and identifier fields.
  /// Case-insensitive search.
  List<HistoryEntry> search(String query) {
    if (query.trim().isEmpty) {
      return history;
    }

    metrics.searches++;
    final lowerQuery = query.toLowerCase();

    final results = _history.where((entry) {
      return entry.title.toLowerCase().contains(lowerQuery) ||
          (entry.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (entry.creator?.toLowerCase().contains(lowerQuery) ?? false) ||
          entry.identifier.toLowerCase().contains(lowerQuery);
    }).toList();

    if (kDebugMode) {
      print('[HistoryService] Search "$query": ${results.length} results');
    }

    return results;
  }

  /// Filter history entries by date range
  ///
  /// Returns entries visited between [start] and [end] (inclusive).
  List<HistoryEntry> filterByDateRange(DateTime start, DateTime end) {
    metrics.filters++;

    final results = _history.where((entry) {
      return entry.visitedAt.isAfter(start) && entry.visitedAt.isBefore(end);
    }).toList();

    if (kDebugMode) {
      print('[HistoryService] Filter by date: ${results.length} results');
    }

    return results;
  }

  /// Filter history entries by creator
  ///
  /// Returns entries where creator matches (case-insensitive).
  List<HistoryEntry> filterByCreator(String creator) {
    if (creator.trim().isEmpty) {
      return history;
    }

    metrics.filters++;
    final lowerCreator = creator.toLowerCase();

    return _history
        .where((entry) =>
            entry.creator?.toLowerCase().contains(lowerCreator) ?? false)
        .toList();
  }

  /// Get sorted history entries
  ///
  /// Returns a new list sorted according to the specified option.
  List<HistoryEntry> getSorted(HistorySortOption option) {
    final sorted = List<HistoryEntry>.from(_history);

    switch (option) {
      case HistorySortOption.recentFirst:
        sorted.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
        break;
      case HistorySortOption.oldestFirst:
        sorted.sort((a, b) => a.visitedAt.compareTo(b.visitedAt));
        break;
      case HistorySortOption.titleAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case HistorySortOption.titleDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
      case HistorySortOption.creatorAsc:
        sorted.sort((a, b) {
          final aCreator = a.creator ?? '';
          final bCreator = b.creator ?? '';
          return aCreator.compareTo(bCreator);
        });
        break;
      case HistorySortOption.creatorDesc:
        sorted.sort((a, b) {
          final aCreator = a.creator ?? '';
          final bCreator = b.creator ?? '';
          return bCreator.compareTo(aCreator);
        });
        break;
      case HistorySortOption.sizeLargest:
        sorted.sort((a, b) => b.totalSize.compareTo(a.totalSize));
        break;
      case HistorySortOption.sizeSmallest:
        sorted.sort((a, b) => a.totalSize.compareTo(b.totalSize));
        break;
    }

    return sorted;
  }

  /// Add multiple entries to history (batch operation)
  ///
  /// More efficient than calling addToHistory multiple times.
  /// Returns the number of entries added.
  int addBatch(List<HistoryEntry> entries) {
    if (entries.isEmpty) return 0;

    int addedCount = 0;
    for (final entry in entries) {
      // Remove existing entry with same identifier if exists
      _history.removeWhere((e) => e.identifier == entry.identifier);
      _history.insert(0, entry);
      addedCount++;
    }

    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeRange(_maxHistorySize, _history.length);
    }

    metrics.adds += addedCount;
    notifyListeners();
    _scheduleSave();

    if (kDebugMode) {
      print('[HistoryService] Batch add: $addedCount entries');
    }

    return addedCount;
  }

  /// Remove multiple entries from history (batch operation)
  ///
  /// More efficient than calling removeFromHistory multiple times.
  /// Returns the number of entries removed.
  int removeBatch(List<String> identifiers) {
    if (identifiers.isEmpty) return 0;

    final initialSize = _history.length;
    _history.removeWhere((e) => identifiers.contains(e.identifier));
    final removedCount = initialSize - _history.length;

    if (removedCount > 0) {
      metrics.removes += removedCount;
      notifyListeners();
      _scheduleSave();

      if (kDebugMode) {
        print('[HistoryService] Batch remove: $removedCount entries');
      }
    }

    return removedCount;
  }

  /// Remove entries older than the specified duration
  ///
  /// For example, removeOlderThan(Duration(days: 30)) removes all entries
  /// older than 30 days.
  ///
  /// Returns the number of entries removed.
  int removeOlderThan(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    final initialSize = _history.length;

    _history.removeWhere((entry) => entry.visitedAt.isBefore(cutoff));

    final removedCount = initialSize - _history.length;

    if (removedCount > 0) {
      metrics.removes += removedCount;
      notifyListeners();
      _scheduleSave();

      if (kDebugMode) {
        print('[HistoryService] Removed $removedCount entries older than '
            '${duration.inDays} days');
      }
    }

    return removedCount;
  }

  /// Get history statistics
  ///
  /// Returns useful statistics about the history:
  /// - Total entries
  /// - Unique creators
  /// - Total size of all archives
  /// - Average size
  /// - Date range (oldest to newest)
  HistoryStatistics getStatistics() {
    if (_history.isEmpty) {
      return const HistoryStatistics(
        totalEntries: 0,
        uniqueCreators: 0,
        totalSize: 0,
        averageSize: 0,
        oldestEntry: null,
        newestEntry: null,
      );
    }

    final creators = <String>{};
    int totalSize = 0;

    for (final entry in _history) {
      if (entry.creator != null && entry.creator!.isNotEmpty) {
        creators.add(entry.creator!);
      }
      totalSize += entry.totalSize;
    }

    final sorted = List<HistoryEntry>.from(_history)
      ..sort((a, b) => a.visitedAt.compareTo(b.visitedAt));

    return HistoryStatistics(
      totalEntries: _history.length,
      uniqueCreators: creators.length,
      totalSize: totalSize,
      averageSize: totalSize ~/ _history.length,
      oldestEntry: sorted.first,
      newestEntry: sorted.last,
    );
  }

  /// Export history as JSON string
  ///
  /// Can be used for backup or transfer to another device.
  String exportToJson() {
    final jsonList = _history.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import history from JSON string
  ///
  /// Merges with existing history (deduplicates by identifier).
  /// Returns the number of entries imported.
  Future<int> importFromJson(String jsonString) async {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final entries = jsonList
          .map((json) => HistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return addBatch(entries);
    } catch (e) {
      if (kDebugMode) {
        print('[HistoryService] Error importing: $e');
      }
      return 0;
    }
  }

  /// Schedule a save operation (debounced)
  ///
  /// Saves are debounced by 2 seconds to avoid excessive writes.
  void _scheduleSave() {
    _needsSave = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_needsSave) {
        _saveHistory();
        _needsSave = false;
      }
    });
  }

  /// Dispose resources and save pending changes
  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_needsSave) {
      _saveHistory();
    }

    if (kDebugMode) {
      print('[HistoryService] Final metrics: $metrics');
    }

    super.dispose();
  }

  /// Get current metrics for monitoring
  HistoryMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  void resetMetrics() {
    metrics.reset();
    if (kDebugMode) {
      print('[HistoryService] Metrics reset');
    }
  }
}

/// History statistics
class HistoryStatistics {
  final int totalEntries;
  final int uniqueCreators;
  final int totalSize;
  final int averageSize;
  final HistoryEntry? oldestEntry;
  final HistoryEntry? newestEntry;

  const HistoryStatistics({
    required this.totalEntries,
    required this.uniqueCreators,
    required this.totalSize,
    required this.averageSize,
    this.oldestEntry,
    this.newestEntry,
  });

  String get formattedTotalSize => _formatBytes(totalSize);
  String get formattedAverageSize => _formatBytes(averageSize);

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
    return 'HistoryStatistics{'
        'entries: $totalEntries, '
        'creators: $uniqueCreators, '
        'total: $formattedTotalSize, '
        'avg: $formattedAverageSize'
        '}';
  }
}

/// History service performance metrics
///
/// Tracks operations for monitoring and optimization:
/// - Adds/removes for activity tracking
/// - Searches/filters for usage patterns
/// - Clears for cleanup operations
class HistoryMetrics {
  /// Number of entries added to history
  int adds = 0;

  /// Number of entries removed from history
  int removes = 0;

  /// Number of clear operations
  int clears = 0;

  /// Number of search operations
  int searches = 0;

  /// Number of filter operations
  int filters = 0;

  /// Reset all metrics to zero
  void reset() {
    adds = 0;
    removes = 0;
    clears = 0;
    searches = 0;
    filters = 0;
  }

  /// Total number of operations
  int get totalOperations => adds + removes + clears + searches + filters;

  @override
  String toString() {
    return 'HistoryMetrics{'
        'adds: $adds, '
        'removes: $removes, '
        'clears: $clears, '
        'searches: $searches, '
        'filters: $filters, '
        'total: $totalOperations'
        '}';
  }
}
