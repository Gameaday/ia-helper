import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/archive_metadata.dart';
import '../models/search_result.dart';
import '../models/rate_limit_status.dart';
import '../models/api_intensity_settings.dart';
import 'internet_archive_api.dart';
import 'history_service.dart';
import 'metadata_cache.dart';
import 'local_archive_storage.dart';
import 'ia_http_client.dart';
import 'bandwidth_throttle.dart';
import '../core/constants/internet_archive_constants.dart';

/// Archive Service - Pure Dart/Flutter implementation
///
/// This service provides a clean interface for interacting with the Internet Archive,
/// now using a pure Dart implementation instead of FFI.
///
/// Benefits of pure Dart approach:
/// - No native library dependencies or build complexity
/// - Works on all Flutter platforms (Android, iOS, Web, Desktop)
/// - Easier to debug and maintain
/// - Better error messages and handling
/// - No race conditions from FFI boundaries

class ArchiveService extends ChangeNotifier {
  final MetadataCache _cache;
  late final InternetArchiveApi _api;
  final HistoryService? _historyService;
  final LocalArchiveStorage? _localArchiveStorage;
  
  // Validation cache - stores identifier validation results
  final Map<String, bool> _validationCache = {};
  static const _validationCacheDuration = Duration(minutes: 30);
  final Map<String, DateTime> _validationCacheTimestamps = {};
  static const _validationCacheKey = 'archive_service_validation_cache';
  static const _validationCacheTimestampsKey = 'archive_service_validation_cache_timestamps';
  bool _cacheLoaded = false;

  ArchiveService({
    HistoryService? historyService,
    LocalArchiveStorage? localArchiveStorage,
    IAHttpClient? httpClient,
    BandwidthThrottle? bandwidthThrottle,
    MetadataCache? cache,
  }) : _cache = cache ?? MetadataCache(),
       _historyService = historyService,
       _localArchiveStorage = localArchiveStorage {
    _api = InternetArchiveApi(
      client: httpClient,
      cache: _cache,
      bandwidthThrottle: bandwidthThrottle,
    );
  }

  // State
  bool _isInitialized = true; // No initialization needed for pure Dart
  bool _isLoading = false;
  String? _error;
  ArchiveMetadata? _currentMetadata;
  List<ArchiveFile> _filteredFiles = [];
  List<SearchResult> _suggestions = [];

  // File filtering state
  String? _includeFormats;
  String? _excludeFormats;
  String? _maxSize;
  String? _sourceTypes;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ArchiveMetadata? get currentMetadata => _currentMetadata;
  List<ArchiveFile> get filteredFiles => _filteredFiles;
  bool get canCancel => _isLoading; // Simplified - no request tracking needed
  List<SearchResult> get suggestions => _suggestions;

  /// Initialize the service
  Future<void> initialize() async {
    _isInitialized = true;
    _error = null;
    
    // Load validation cache from persistent storage
    await _loadValidationCache();
    
    notifyListeners();
  }

  /// Load validation cache from SharedPreferences
  Future<void> _loadValidationCache() async {
    if (_cacheLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cache map
      final cacheJson = prefs.getString(_validationCacheKey);
      if (cacheJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheJson);
        _validationCache.addAll(decoded.map((key, value) => MapEntry(key, value as bool)));
      }
      
      // Load timestamps
      final timestampsJson = prefs.getString(_validationCacheTimestampsKey);
      if (timestampsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(timestampsJson);
        _validationCacheTimestamps.addAll(
          decoded.map((key, value) => MapEntry(key, DateTime.parse(value as String)))
        );
      }
      
      // Clean expired entries
      _cleanExpiredCacheEntries();
      
      _cacheLoaded = true;
      
      if (kDebugMode) {
        debugPrint('[ArchiveService] Loaded validation cache: ${_validationCache.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ArchiveService] Failed to load validation cache: $e');
      }
      // Don't throw - just start with empty cache
    }
  }

  /// Save validation cache to SharedPreferences
  Future<void> _saveValidationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save cache map
      final cacheJson = jsonEncode(_validationCache);
      await prefs.setString(_validationCacheKey, cacheJson);
      
      // Save timestamps
      final timestampsJson = jsonEncode(
        _validationCacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String()))
      );
      await prefs.setString(_validationCacheTimestampsKey, timestampsJson);
      
      if (kDebugMode) {
        debugPrint('[ArchiveService] Saved validation cache: ${_validationCache.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ArchiveService] Failed to save validation cache: $e');
      }
      // Don't throw - cache will just not persist
    }
  }

  /// Remove expired entries from cache
  void _cleanExpiredCacheEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _validationCacheTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age > _validationCacheDuration) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _validationCache.remove(key);
      _validationCacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty && kDebugMode) {
      debugPrint('[ArchiveService] Cleaned ${expiredKeys.length} expired cache entries');
    }
  }

  /// Validate if an identifier exists on Archive.org
  ///
  /// Uses a lightweight HEAD request to check existence without fetching full metadata.
  /// This is much faster than fetchMetadata() and doesn't affect cache or state.
  ///
  /// Automatically tries lowercase normalization if original fails (Archive.org identifiers
  /// are case-insensitive but typically stored in lowercase).
  ///
  /// Returns:
  /// - true if identifier exists (HTTP 200)
  /// - false if identifier doesn't exist (HTTP 404 or other errors)
  ///
  /// Example:
  /// ```dart
  /// final validId = await archiveService.validateIdentifier('Mario');
  /// if (validId != null) {
  ///   // Use validId ('mario') to open archive
  /// }
  /// ```
  Future<String?> validateIdentifier(String identifier) async {
    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty) {
      return null;
    }

    // Check cache first - instant result!
    final cachedResult = _getValidationFromCache(trimmedIdentifier);
    if (cachedResult != null) {
      if (kDebugMode) {
        debugPrint('[ArchiveService] Validation cache hit: $trimmedIdentifier = ${cachedResult.isValid}');
      }
      return cachedResult.isValid ? cachedResult.identifier : null;
    }

    if (kDebugMode) {
      debugPrint('[ArchiveService] Validation cache miss: $trimmedIdentifier');
    }

    // Try original identifier first
    final originalExists = await _checkIdentifierExists(trimmedIdentifier);
    if (originalExists) {
      _cacheValidationResult(trimmedIdentifier, isValid: true, workingIdentifier: trimmedIdentifier);
      return trimmedIdentifier;
    }

    // If original fails and has uppercase, try lowercase normalization
    final lowercaseId = trimmedIdentifier.toLowerCase();
    if (lowercaseId != trimmedIdentifier) {
      if (kDebugMode) {
        debugPrint('[ArchiveService] Trying lowercase: $lowercaseId');
      }
      final lowercaseExists = await _checkIdentifierExists(lowercaseId);
      if (lowercaseExists) {
        // Cache both the original (invalid) and lowercase (valid) versions
        _cacheValidationResult(trimmedIdentifier, isValid: false);
        _cacheValidationResult(lowercaseId, isValid: true, workingIdentifier: lowercaseId);
        return lowercaseId; // Return the working lowercase version
      }
    }

    // Cache negative result
    _cacheValidationResult(trimmedIdentifier, isValid: false);
    return null;
  }

  /// Get validation result from cache if available and not expired
  ({bool isValid, String? identifier})? _getValidationFromCache(String identifier) {
    if (!_validationCache.containsKey(identifier)) {
      return null;
    }

    final timestamp = _validationCacheTimestamps[identifier];
    if (timestamp == null) {
      return null;
    }

    // Check if cache entry is still valid
    final age = DateTime.now().difference(timestamp);
    if (age > _validationCacheDuration) {
      // Cache expired - remove it
      _validationCache.remove(identifier);
      _validationCacheTimestamps.remove(identifier);
      return null;
    }

    final isValid = _validationCache[identifier]!;
    return (isValid: isValid, identifier: isValid ? identifier : null);
  }

  /// Cache a validation result with timestamp
  void _cacheValidationResult(String identifier, {required bool isValid, String? workingIdentifier}) {
    _validationCache[identifier] = isValid;
    _validationCacheTimestamps[identifier] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('[ArchiveService] Cached validation: $identifier = $isValid${workingIdentifier != null && workingIdentifier != identifier ? ' (working: $workingIdentifier)' : ''}');
    }
    
    // Persist cache to disk asynchronously (don't await to avoid blocking)
    _saveValidationCache();
  }

  /// Internal method to check if a single identifier exists
  Future<bool> _checkIdentifierExists(String identifier) async {
    try {
      // Use metadata endpoint for validation
      final url = 'https://archive.org/metadata/$identifier';
      
      if (kDebugMode) {
        debugPrint('[ArchiveService] Validating identifier: $identifier');
      }

      // Use GET request (HEAD returns 405 on Archive.org)
      // Archive.org returns 200 with empty JSON {} for non-existent items
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[ArchiveService] Validation timeout for: $identifier');
          }
          return http.Response('Timeout', 408);
        },
      );

      // Check if response is successful
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[ArchiveService] Identifier validation: $identifier = false (${response.statusCode})');
        }
        return false;
      }

      // Archive.org returns {} for non-existent items
      // Check if response has actual metadata
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final exists = json.containsKey('metadata') || 
                      json.containsKey('files') || 
                      json.containsKey('created');
        
        if (kDebugMode) {
          debugPrint('[ArchiveService] Identifier validation: $identifier = $exists (has metadata: ${json.containsKey('metadata')})');
        }
        
        return exists;
      } catch (e) {
        // JSON parsing error = invalid response
        if (kDebugMode) {
          debugPrint('[ArchiveService] JSON parsing error for $identifier: $e');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ArchiveService] Validation error for $identifier: $e');
      }
      return false;
    }
  }

  /// Fetch metadata for an archive (cache-first strategy)
  ///
  /// Respects API intensity settings:
  /// - Cache Only: Returns cached data only, never makes API calls
  /// - Minimal: Fetches basic metadata only
  /// - Standard: Fetches metadata with standard fields
  /// - Full: Fetches complete metadata with all available data
  Future<ArchiveMetadata> fetchMetadata(
    String identifier, {
    bool forceRefresh = false,
  }) async {
    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty) {
      _error = 'Invalid identifier: cannot be empty';
      notifyListeners();
      throw Exception(_error);
    }

    _isLoading = true;
    _error = null;
    _currentMetadata = null;
    _filteredFiles = [];
    _suggestions = [];
    notifyListeners();

    try {
      // Load API intensity settings
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('api_intensity_settings');
      final intensitySettings = jsonString != null
          ? ApiIntensitySettings.fromJson(
              jsonDecode(jsonString) as Map<String, dynamic>,
            )
          : ApiIntensitySettings.standard();

      if (kDebugMode) {
        print('[ArchiveService] API Intensity: ${intensitySettings.level}');
      }

      ArchiveMetadata metadata;

      // Try to get from cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = await _cache.getCachedMetadata(trimmedIdentifier);
        if (cached != null) {
          // Check if cache is stale
          final syncFrequency = await _cache.getSyncFrequency();
          if (!cached.isStale(syncFrequency)) {
            // Use cached metadata (cache hit)
            metadata = cached.metadata;
            _currentMetadata = metadata;
            _filteredFiles = metadata.files;

            // Apply current filters if any
            if (_includeFormats != null ||
                _excludeFormats != null ||
                _maxSize != null ||
                _sourceTypes != null) {
              await _applyFilters();
            }

            _error = null;
            _isLoading = false;
            notifyListeners();

            return metadata;
          }
        }

        // Cache Only mode: If no valid cache, throw exception
        if (intensitySettings.level == ApiIntensityLevel.cacheOnly) {
          _error = 'Cache Only mode: No cached data available for $trimmedIdentifier';
          _isLoading = false;
          notifyListeners();
          throw Exception(_error);
        }
      }

      // For force refresh, respect Cache Only mode
      if (forceRefresh && intensitySettings.level == ApiIntensityLevel.cacheOnly) {
        _error = 'Cache Only mode: Cannot refresh from API';
        _isLoading = false;
        notifyListeners();
        throw Exception(_error);
      }

      // Cache miss or stale - fetch from API
      // Note: Internet Archive's metadata endpoint returns all fields in one call.
      // Future enhancement: Add parameters to control extended data like reviews, 
      // related items, or statistics based on intensity level.
      metadata = await _api.fetchMetadata(trimmedIdentifier);

      // Cache the fetched metadata
      await _cache.cacheMetadata(metadata);

      _currentMetadata = metadata;
      _filteredFiles = metadata.files;

      // Apply current filters if any
      if (_includeFormats != null ||
          _excludeFormats != null ||
          _maxSize != null ||
          _sourceTypes != null) {
        await _applyFilters();
      }

      // Add to history if history service is available
      if (_historyService != null) {
        _historyService.addToHistory(
          HistoryEntry(
            identifier: metadata.identifier,
            title: metadata.title ?? metadata.identifier,
            description: metadata.description,
            creator: metadata.creator,
            totalFiles: metadata.totalFiles,
            totalSize: metadata.totalSize,
            visitedAt: DateTime.now(),
          ),
        );
      }

      _error = null;
      _isLoading = false;
      notifyListeners();

      return metadata;
    } catch (e, stackTrace) {
      _error = 'Failed to fetch metadata: ${e.toString()}';
      _currentMetadata = null;
      _filteredFiles = [];
      _isLoading = false;

      // If it's a NotFoundException, try to get suggestions
      if (e.toString().contains('not found') || e.toString().contains('404')) {
        try {
          final suggestions = await _api.suggestAlternativeIdentifiers(
            trimmedIdentifier,
          );
          _suggestions = suggestions;
        } catch (suggestionError) {
          if (kDebugMode) {
            print('Failed to get suggestions: $suggestionError');
          }
        }
      }

      if (kDebugMode) {
        print('Error fetching metadata: $e');
        print('Stack trace: $stackTrace');
      }

      notifyListeners();
      rethrow;
    }
  }

  /// Apply file filters
  Future<void> applyFilters({
    String? includeFormats,
    String? excludeFormats,
    String? maxSize,
    String? sourceTypes,
  }) async {
    _includeFormats = includeFormats;
    _excludeFormats = excludeFormats;
    _maxSize = maxSize;
    _sourceTypes = sourceTypes;

    await _applyFilters();
  }

  /// Apply file filters (with Flutter screen compatible signature)
  void filterFiles({
    List<String>? includeFormats,
    List<String>? excludeFormats,
    String? maxSize,
    bool includeOriginal = true,
    bool includeDerivative = true,
    bool includeMetadata = true,
  }) {
    if (_currentMetadata == null) {
      _error = 'No metadata available to filter';
      notifyListeners();
      return;
    }

    // Convert list parameters to comma-separated strings
    _includeFormats = includeFormats != null && includeFormats.isNotEmpty
        ? includeFormats.join(',')
        : null;
    _excludeFormats = excludeFormats != null && excludeFormats.isNotEmpty
        ? excludeFormats.join(',')
        : null;
    _maxSize = maxSize;

    // Build source types filter
    final sourceTypes = <String>[];
    if (includeOriginal) sourceTypes.add('original');
    if (includeDerivative) sourceTypes.add('derivative');
    if (includeMetadata) sourceTypes.add('metadata');
    _sourceTypes = sourceTypes.isNotEmpty ? sourceTypes.join(',') : null;

    // Apply filters synchronously (no await needed)
    _applyFiltersSync();
  }

  /// Internal method to apply filters
  Future<void> _applyFilters() async {
    if (_currentMetadata == null) return;

    try {
      // Start with all files
      var files = _currentMetadata!.files;

      // Apply include formats filter
      if (_includeFormats != null && _includeFormats!.isNotEmpty) {
        final formats = _includeFormats!
            .split(',')
            .map((f) => f.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final ext = file.name.split('.').last.toLowerCase();
          return formats.contains(ext);
        }).toList();
      }

      // Apply exclude formats filter
      if (_excludeFormats != null && _excludeFormats!.isNotEmpty) {
        final formats = _excludeFormats!
            .split(',')
            .map((f) => f.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final ext = file.name.split('.').last.toLowerCase();
          return !formats.contains(ext);
        }).toList();
      }

      // Apply max size filter
      if (_maxSize != null && _maxSize!.isNotEmpty) {
        final maxBytes = _parseSize(_maxSize!);
        if (maxBytes > 0) {
          files = files.where((file) {
            return (file.size ?? 0) <= maxBytes;
          }).toList();
        }
      }

      // Apply source types filter (original vs derivative)
      if (_sourceTypes != null && _sourceTypes!.isNotEmpty) {
        final types = _sourceTypes!
            .split(',')
            .map((t) => t.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final source = file.source?.toLowerCase() ?? '';
          return types.any((type) => source.contains(type));
        }).toList();
      }

      _filteredFiles = files;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error applying filters: $e');
      }
      // On error, show all files
      _filteredFiles = _currentMetadata!.files;
      notifyListeners();
    }
  }

  /// Internal method to apply filters synchronously
  void _applyFiltersSync() {
    if (_currentMetadata == null) return;

    try {
      // Start with all files
      var files = _currentMetadata!.files;

      // Apply include formats filter
      if (_includeFormats != null && _includeFormats!.isNotEmpty) {
        final formats = _includeFormats!
            .split(',')
            .map((f) => f.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final ext = file.name.split('.').last.toLowerCase();
          final format = file.format?.toLowerCase() ?? '';
          return formats.contains(ext) || formats.contains(format);
        }).toList();
      }

      // Apply exclude formats filter
      if (_excludeFormats != null && _excludeFormats!.isNotEmpty) {
        final formats = _excludeFormats!
            .split(',')
            .map((f) => f.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final ext = file.name.split('.').last.toLowerCase();
          final format = file.format?.toLowerCase() ?? '';
          return !formats.contains(ext) && !formats.contains(format);
        }).toList();
      }

      // Apply max size filter
      if (_maxSize != null && _maxSize!.isNotEmpty) {
        final maxBytes = _parseSize(_maxSize!);
        if (maxBytes > 0) {
          files = files.where((file) {
            return (file.size ?? 0) <= maxBytes;
          }).toList();
        }
      }

      // Apply source types filter (original vs derivative)
      if (_sourceTypes != null && _sourceTypes!.isNotEmpty) {
        final types = _sourceTypes!
            .split(',')
            .map((t) => t.trim().toLowerCase())
            .toList();
        files = files.where((file) {
          final source = file.source?.toLowerCase() ?? '';
          // If no source types are specified, include all
          if (types.isEmpty) return true;
          // Check if file source matches any of the allowed types
          return types.any(
            (type) =>
                source.contains(type) || (source.isEmpty && type == 'original'),
          );
        }).toList();
      }

      _filteredFiles = files;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error applying filters: $e');
      }
      // On error, show all files
      _filteredFiles = _currentMetadata!.files;
      _error = 'Error applying filters: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Parse size string (e.g., "10MB", "1GB") to bytes
  int _parseSize(String sizeStr) {
    final regex = RegExp(
      r'(\d+(?:\.\d+)?)\s*([KMGT]?B?)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(sizeStr.trim());

    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = (match.group(2) ?? '').toUpperCase();

    switch (unit) {
      case 'KB':
      case 'K':
        return (value * 1024).toInt();
      case 'MB':
      case 'M':
        return (value * 1024 * 1024).toInt();
      case 'GB':
      case 'G':
        return (value * 1024 * 1024 * 1024).toInt();
      case 'TB':
      case 'T':
        return (value * 1024 * 1024 * 1024 * 1024).toInt();
      default:
        return value.toInt();
    }
  }

  /// Clear current metadata
  void clearMetadata() {
    _currentMetadata = null;
    _filteredFiles = [];
    _error = null;
    _suggestions = [];
    _includeFormats = null;
    _excludeFormats = null;
    _maxSize = null;
    _sourceTypes = null;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _includeFormats = null;
    _excludeFormats = null;
    _maxSize = null;
    _sourceTypes = null;

    if (_currentMetadata != null) {
      _filteredFiles = _currentMetadata!.files;
      notifyListeners();
    }
  }

  /// Calculate total size of selected files
  int calculateTotalSize(List<ArchiveFile> files) {
    return files.fold<int>(0, (sum, file) => sum + (file.size ?? 0));
  }

  /// Search for archives using Internet Archive API
  Future<void> searchArchives(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use standardized search URL builder
      final searchUrl = IAUtils.buildSearchUrl(
        query: query,
        rows: IASearchParams.defaultRows,
        fields: IASearchParams.defaultFields,
      );

      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final docs = jsonData['response']?['docs'] as List<dynamic>? ?? [];

        _suggestions = docs
            .map((doc) => SearchResult.fromJson(doc as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print('Search API returned status ${response.statusCode}');
        }
        _suggestions = [];
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching archives: $e');
      }
      _suggestions = [];
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Notify listeners of file selection changes (for UI updates)
  void notifyFileSelectionChanged() {
    notifyListeners();
  }

  /// Cancel current operation (no-op for simplified FFI but kept for compatibility)
  void cancelOperation() {
    _isLoading = false;
    notifyListeners();
  }

  /// Get available formats from current metadata
  Set<String> getAvailableFormats() {
    if (_currentMetadata == null) {
      return {};
    }

    final formats = <String>{};
    for (final file in _currentMetadata!.files) {
      // Add format if available
      if (file.format != null && file.format!.isNotEmpty) {
        formats.add(file.format!.toLowerCase());
      }
      // Also extract extension from filename
      final parts = file.name.split('.');
      if (parts.length > 1) {
        formats.add(parts.last.toLowerCase());
      }
    }
    return formats;
  }

  /// Download a file from the given URL to the specified output path
  ///
  /// [url] - The URL to download from
  /// [outputPath] - The local file path where the file will be saved
  /// [onProgress] - Optional callback for download progress updates (downloaded bytes, total bytes)
  Future<void> downloadFile(
    String url,
    String outputPath, {
    Function(int downloaded, int total)? onProgress,
  }) async {
    try {
      await _api.downloadFile(url, outputPath, onProgress: onProgress);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading file: $e');
      }
      rethrow;
    }
  }

  /// Validate file checksum
  ///
  /// [filePath] - Path to the file to validate
  /// [expectedHash] - The expected hash value
  /// [hashType] - Type of hash (md5, sha1, sha256, etc.)
  ///
  /// Returns true if the checksum matches, false otherwise
  Future<bool> validateChecksum(
    String filePath,
    String expectedHash, {
    String hashType = 'md5',
  }) async {
    try {
      return await _api.validateChecksum(filePath, expectedHash, hashType);
    } catch (e) {
      if (kDebugMode) {
        print('Error validating checksum: $e');
      }
      rethrow;
    }
  }

  /// Decompress/extract an archive file
  ///
  /// [archivePath] - Path to the archive file
  /// [outputDir] - Directory where files will be extracted
  ///
  /// Returns a list of extracted file paths
  Future<List<String>> decompressFile(
    String archivePath,
    String outputDir,
  ) async {
    try {
      return await _api.decompressFile(archivePath, outputDir);
    } catch (e) {
      if (kDebugMode) {
        print('Error decompressing file: $e');
      }
      rethrow;
    }
  }

  // Cache management methods

  /// Check if an archive is cached offline
  Future<bool> isCached(String identifier) async {
    return await _cache.isCached(identifier);
  }

  /// Check if an archive has been downloaded
  bool isDownloaded(String identifier) {
    return _localArchiveStorage?.hasArchive(identifier) ?? false;
  }

  /// Get cached metadata without fetching from API
  Future<ArchiveMetadata?> getCachedMetadata(String identifier) async {
    final cached = await _cache.getCachedMetadata(identifier);
    return cached?.metadata;
  }

  /// Pin an archive to prevent auto-purge
  Future<void> pinArchive(String identifier) async {
    await _cache.pinArchive(identifier);
    notifyListeners();
  }

  /// Unpin an archive to allow auto-purge
  Future<void> unpinArchive(String identifier) async {
    await _cache.unpinArchive(identifier);
    notifyListeners();
  }

  /// Toggle pin status for an archive
  Future<void> togglePin(String identifier) async {
    await _cache.togglePin(identifier);
    notifyListeners();
  }

  /// Manually sync metadata from API (force refresh)
  Future<ArchiveMetadata> syncMetadata(String identifier) async {
    return await fetchMetadata(identifier, forceRefresh: true);
  }

  /// Purge stale cache entries
  /// Automatically protects downloaded archives from purging
  Future<int> purgeStaleCaches({List<String>? protectedIdentifiers}) async {
    // Build list of protected identifiers
    final protected = <String>{};

    // Add user-provided protected identifiers
    if (protectedIdentifiers != null) {
      protected.addAll(protectedIdentifiers);
    }

    // Add downloaded archives (they should never be purged)
    if (_localArchiveStorage != null) {
      final downloadedIdentifiers = _localArchiveStorage.archives.keys;
      protected.addAll(downloadedIdentifiers);
    }

    return await _cache.purgeStaleCaches(
      protectedIdentifiers: protected.toList(),
    );
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    return await _cache.getCacheStats();
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _cache.clearAllCache();
    notifyListeners();
  }

  /// Get current rate limiter status
  RateLimitStatus getRateLimitStatus() {
    return _api.client.getRateLimitStatus();
  }

  @override
  void dispose() {
    _api.dispose();
    _currentMetadata = null;
    _filteredFiles = [];
    _suggestions = [];
    super.dispose();
  }
}
