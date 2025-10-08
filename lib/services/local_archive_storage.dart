import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_archive.dart';

/// Service for managing locally downloaded archives
///
/// Provides persistent storage of downloaded archive metadata,
/// allowing the app to track and manage local archive collections.
class LocalArchiveStorage extends ChangeNotifier {
  static const String _storageKey = 'downloaded_archives';
  static const String _versionKey = 'archive_storage_version';
  static const int _currentVersion = 1;

  SharedPreferences? _prefs;
  Map<String, DownloadedArchive> _archives = {};
  bool _isInitialized = false;

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
  Future<void> saveArchive(DownloadedArchive archive) async {
    _archives[archive.identifier] = archive;
    await _saveArchives();
    notifyListeners();
    debugPrint('Saved archive: ${archive.identifier}');
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
  Future<void> removeArchive(String identifier) async {
    _archives.remove(identifier);
    await _saveArchives();
    notifyListeners();
    debugPrint('Removed archive: $identifier');
  }

  /// Update an archive's access time
  Future<void> markArchiveAccessed(String identifier) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.markAccessed();
      await _saveArchives();
      notifyListeners();
    }
  }

  /// Update a specific file's download state
  Future<void> updateFileState(
    String identifier,
    String filename,
    bool isDownloaded,
  ) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.updateFileState(filename, isDownloaded);
      await _saveArchives();
      notifyListeners();
    }
  }

  /// Add tags to an archive
  Future<void> addTags(String identifier, List<String> tags) async {
    final archive = _archives[identifier];
    if (archive != null) {
      final currentTags = Set<String>.from(archive.tags);
      currentTags.addAll(tags);
      _archives[identifier] = archive.copyWith(tags: currentTags.toList());
      await _saveArchives();
      notifyListeners();
    }
  }

  /// Remove tags from an archive
  Future<void> removeTags(String identifier, List<String> tags) async {
    final archive = _archives[identifier];
    if (archive != null) {
      final currentTags = Set<String>.from(archive.tags);
      currentTags.removeAll(tags);
      _archives[identifier] = archive.copyWith(tags: currentTags.toList());
      await _saveArchives();
      notifyListeners();
    }
  }

  /// Update archive notes
  Future<void> updateNotes(String identifier, String? notes) async {
    final archive = _archives[identifier];
    if (archive != null) {
      _archives[identifier] = archive.copyWith(notes: notes);
      await _saveArchives();
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
    // Don't clear data on dispose, it should persist
    super.dispose();
  }
}
