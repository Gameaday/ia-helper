import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/download_progress.dart';
import '../models/archive_metadata.dart';
import '../models/download_statistics.dart';
import '../models/downloaded_archive.dart';
import 'internet_archive_api.dart';
import 'notification_service.dart';
import 'local_archive_storage.dart';

/// Service for managing background downloads with Android WorkManager integration
class BackgroundDownloadService extends ChangeNotifier {
  static const _platform = MethodChannel(
    'com.gameaday.internet_archive_helper/platform',
  );

  final Map<String, DownloadProgress> _activeDownloads = {};
  final Map<String, DownloadProgress> _completedDownloads = {};
  final Map<String, ArchiveMetadata> _downloadMetadata = {};
  final Map<String, List<String>> _downloadFiles =
      {}; // Track selected files per download
  final List<String> _downloadQueue = [];
  Timer? _statusUpdateTimer;
  Timer? _retryTimer;
  bool _isInitialized = false;
  int _maxConcurrentDownloads = 3;
  int _maxRetries = 3;
  LocalArchiveStorage? _archiveStorage;

  Map<String, DownloadProgress> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);
  Map<String, DownloadProgress> get completedDownloads =>
      Map.unmodifiable(_completedDownloads);
  List<String> get downloadQueue => List.unmodifiable(_downloadQueue);
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;
  int get activeDownloadCount => _activeDownloads.length;
  int get completedDownloadCount => _completedDownloads.length;
  int get queuedDownloadCount => _downloadQueue.length;
  int get totalDownloadCount =>
      activeDownloadCount + completedDownloadCount + queuedDownloadCount;
  int get maxRetries => _maxRetries;
  int get maxConcurrentDownloads => _maxConcurrentDownloads;

  /// Get metadata for a specific download (for retry functionality)
  ArchiveMetadata? getDownloadMetadata(String downloadId) {
    return _downloadMetadata[downloadId];
  }

  /// Get selected files for a specific download (for retry functionality)
  List<String>? getDownloadFiles(String downloadId) {
    return _downloadFiles[downloadId];
  }

  /// Get download path for a specific download (for retry functionality)
  /// Returns null if not stored - caller should use default path
  String? getDownloadPath(String downloadId) {
    // Download path is not currently stored per-download
    // Return null to use default path
    return null;
  }

  /// Set maximum retry attempts for failed downloads
  set maxRetries(int value) {
    if (value >= 0 && value <= 10) {
      _maxRetries = value;
      notifyListeners();
    }
  }

  /// Set maximum concurrent downloads
  set maxConcurrentDownloads(int value) {
    if (value >= 1 && value <= 10) {
      _maxConcurrentDownloads = value;
      notifyListeners();
      // Process queue in case we can now handle more downloads
      _processQueue();
    }
  }

  /// Set archive storage service for saving downloaded archives
  void setArchiveStorage(LocalArchiveStorage storage) {
    _archiveStorage = storage;
  }

  // Statistics
  int _totalBytesDownloaded = 0;
  int _totalFilesDownloaded = 0;
  DateTime? _sessionStartTime;

  int get totalBytesDownloaded => _totalBytesDownloaded;
  int get totalFilesDownloaded => _totalFilesDownloaded;
  Duration? get sessionDuration => _sessionStartTime != null
      ? DateTime.now().difference(_sessionStartTime!)
      : null;

  /// Initialize the background download service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('BackgroundDownloadService already initialized');
      return;
    }

    try {
      // Setup method channel communication with Android
      // Use try-catch to handle platform-specific errors gracefully
      try {
        _platform.setMethodCallHandler(_handleMethodCall);
      } catch (e) {
        debugPrint('Failed to setup method channel handler: $e');
        // Continue initialization even if method channel fails
        // as core functionality may still work
      }

      // Start periodic status updates (faster for better feedback)
      _statusUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (
        _,
      ) {
        try {
          _updateDownloadStatuses();
        } catch (e) {
          debugPrint('Error updating download statuses: $e');
        }
      });

      // Start retry timer for failed downloads
      _retryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        try {
          _retryFailedDownloads();
        } catch (e) {
          debugPrint('Error retrying failed downloads: $e');
        }
      });

      // Initialize session tracking
      _sessionStartTime = DateTime.now();

      _isInitialized = true;

      debugPrint('BackgroundDownloadService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize background download service: $e');
      // Don't rethrow - service can be partially functional
      _isInitialized = false;
    }
  }

  /// Dispose of resources
  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Validate archive metadata before downloading
  /// Checks if the archive exists and has downloadable files
  Future<bool> validateArchiveForDownload(String identifier) async {
    try {
      // Use Internet Archive API to fetch and validate archive metadata
      final api = InternetArchiveApi();
      final metadata = await api.fetchMetadata(identifier);

      // Check if archive has files available for download
      if (metadata.files.isEmpty) {
        debugPrint(
          'Archive validation failed: no files available in $identifier',
        );
        api.dispose();
        return false;
      }

      debugPrint(
        'Archive $identifier validated successfully (${metadata.files.length} files)',
      );
      api.dispose();
      return true;
    } catch (e) {
      debugPrint('Archive validation error for $identifier: $e');
      return false;
    }
  }

  /// Get archive metadata for a download
  /// Useful for displaying file information before starting download
  Future<ArchiveMetadata?> getArchiveMetadata(String identifier) async {
    try {
      final api = InternetArchiveApi();
      final metadata = await api.fetchMetadata(identifier);
      api.dispose();
      return metadata;
    } catch (e) {
      debugPrint('Failed to fetch archive metadata for $identifier: $e');
      return null;
    }
  }

  /// Handle method calls from Android native code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDownloadProgress':
        _handleDownloadProgress(call.arguments);
        break;
      case 'onDownloadComplete':
        _handleDownloadComplete(call.arguments);
        break;
      case 'onDownloadError':
        _handleDownloadError(call.arguments);
        break;
    }
  }

  /// Start a background download using pure Dart implementation
  Future<String?> startBackgroundDownload({
    required String identifier,
    required List<String> selectedFiles,
    required String downloadPath,
    String? includeFormats,
    String? excludeFormats,
    String? maxSize,
    ArchiveMetadata? metadata,
  }) async {
    try {
      // Use identifier as downloadId
      final downloadId = identifier;

      // Store metadata and files for later use
      if (metadata != null) {
        _downloadMetadata[downloadId] = metadata;
      }
      _downloadFiles[downloadId] = selectedFiles;

      // Calculate total bytes from selected files
      int totalBytes = 0;
      if (metadata != null) {
        for (final fileName in selectedFiles) {
          final file = metadata.files.firstWhere(
            (f) => f.name == fileName,
            orElse: () => ArchiveFile(name: fileName),
          );
          totalBytes += file.size ?? 0;
        }
      }

      // Create download progress entry with total bytes
      _activeDownloads[downloadId] = DownloadProgress(
        downloadId: downloadId,
        identifier: identifier,
        totalFiles: selectedFiles.length,
        totalBytes: totalBytes > 0 ? totalBytes : null,
        downloadedBytes: 0,
        progress: 0.0,
        status: DownloadStatus.queued,
      );
      notifyListeners();

      // Start download in background using Dart isolate
      _startDartDownload(
        downloadId: downloadId,
        identifier: identifier,
        selectedFiles: selectedFiles,
        downloadPath: downloadPath,
        includeFormats: includeFormats,
        excludeFormats: excludeFormats,
        maxSize: maxSize,
      );

      return downloadId;
    } catch (e) {
      debugPrint('Failed to start background download: $e');
      return null;
    }
  }

  /// Start download using pure Dart (no native code needed)
  Future<void> _startDartDownload({
    required String downloadId,
    required String identifier,
    required List<String> selectedFiles,
    required String downloadPath,
    String? includeFormats,
    String? excludeFormats,
    String? maxSize,
  }) async {
    try {
      // Update status to downloading
      if (_activeDownloads.containsKey(downloadId)) {
        _activeDownloads[downloadId] = _activeDownloads[downloadId]!.copyWith(
          status: DownloadStatus.downloading,
        );
        notifyListeners();
      }

      // Use the InternetArchiveApi to download files
      final api = InternetArchiveApi();
      int completedFiles = 0;
      int totalDownloadedBytes = 0;
      DateTime? lastUpdateTime;
      int lastDownloadedBytes = 0;

      for (final fileName in selectedFiles) {
        try {
          final fileUrl = 'https://archive.org/download/$identifier/$fileName';
          final filePath = '$downloadPath/$fileName';
          final fileStartBytes = totalDownloadedBytes;

          // Download file using the API
          await api.downloadFile(
            fileUrl,
            filePath,
            onProgress: (received, total) {
              // Update progress with proper statistics
              if (_activeDownloads.containsKey(downloadId)) {
                final now = DateTime.now();
                final currentTotalBytes = fileStartBytes + received;

                // Calculate transfer speed (bytes per second)
                double? speed;
                if (lastUpdateTime != null) {
                  final timeDiff =
                      now.difference(lastUpdateTime!).inMilliseconds / 1000.0;
                  if (timeDiff > 0) {
                    final bytesDiff = currentTotalBytes - lastDownloadedBytes;
                    speed = bytesDiff / timeDiff;
                  }
                }

                lastUpdateTime = now;
                lastDownloadedBytes = currentTotalBytes;

                // Calculate overall progress (across all files)
                final download = _activeDownloads[downloadId]!;
                final overallTotal = download.totalBytes ?? 0;
                final overallProgress = overallTotal > 0
                    ? currentTotalBytes / overallTotal
                    : 0.0;

                // Calculate ETA if we have speed
                int? eta;
                if (speed != null && speed > 0 && overallTotal > 0) {
                  final remainingBytes = overallTotal - currentTotalBytes;
                  eta = (remainingBytes / speed).round();
                }

                _activeDownloads[downloadId] = download.copyWith(
                  completedFiles: completedFiles,
                  currentFile: fileName,
                  currentFileProgress: (received / total * 100).toDouble(),
                  downloadedBytes: currentTotalBytes,
                  progress: overallProgress,
                  transferSpeed: speed,
                  etaSeconds: eta,
                  status: DownloadStatus.downloading,
                );
                notifyListeners();
              }
            },
          );

          completedFiles++;
          // Update total bytes after file completes
          // Note: We should get the actual file size, but for now use received bytes

          // Update completed count
          if (_activeDownloads.containsKey(downloadId)) {
            _activeDownloads[downloadId] = _activeDownloads[downloadId]!
                .copyWith(
                  completedFiles: completedFiles,
                  currentFileProgress: 0,
                  currentFile: null,
                );
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Failed to download file $fileName: $e');
          // Continue with next file even if one fails
        }
      }

      // Mark as complete
      if (_activeDownloads.containsKey(downloadId)) {
        final download = _activeDownloads.remove(downloadId)!;
        _completedDownloads[downloadId] = download.copyWith(
          status: DownloadStatus.completed,
          completedFiles: completedFiles,
        );

        // Update statistics
        _totalFilesDownloaded += completedFiles;

        // Save to local archive storage
        await _saveToLocalArchive(downloadId, selectedFiles, downloadPath);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Download error for $downloadId: $e');

      // Mark as failed
      if (_activeDownloads.containsKey(downloadId)) {
        _activeDownloads[downloadId] = _activeDownloads[downloadId]!.copyWith(
          status: DownloadStatus.error,
          errorMessage: e.toString(),
        );
        notifyListeners();
      }
    }
  }

  /// Cancel a background download
  Future<bool> cancelDownload(String downloadId) async {
    try {
      final success = await _platform.invokeMethod('cancelDownload', {
        'downloadId': downloadId,
      });

      if (success == true) {
        _activeDownloads.remove(downloadId);
        notifyListeners();
      }

      return success == true;
    } catch (e) {
      debugPrint('Failed to cancel download: $e');
      return false;
    }
  }

  /// Pause a background download
  Future<bool> pauseDownload(String downloadId) async {
    try {
      final success = await _platform.invokeMethod('pauseDownload', {
        'downloadId': downloadId,
      });

      if (success == true && _activeDownloads.containsKey(downloadId)) {
        _activeDownloads[downloadId] = _activeDownloads[downloadId]!.copyWith(
          status: DownloadStatus.paused,
        );
        notifyListeners();
      }

      return success == true;
    } catch (e) {
      debugPrint('Failed to pause download: $e');
      return false;
    }
  }

  /// Resume a paused download
  Future<bool> resumeDownload(String downloadId) async {
    try {
      final success = await _platform.invokeMethod('resumeDownload', {
        'downloadId': downloadId,
      });

      if (success == true && _activeDownloads.containsKey(downloadId)) {
        _activeDownloads[downloadId] = _activeDownloads[downloadId]!.copyWith(
          status: DownloadStatus.downloading,
        );
        notifyListeners();
      }

      return success == true;
    } catch (e) {
      debugPrint('Failed to resume download: $e');
      return false;
    }
  }

  /// Update download statuses from native side
  Future<void> _updateDownloadStatuses() async {
    if (_activeDownloads.isEmpty) return;

    try {
      final statuses = await _platform.invokeMethod('getDownloadStatuses');
      if (statuses is Map) {
        for (final entry in statuses.entries) {
          final downloadId = entry.key as String;
          final statusData = entry.value as Map;

          if (_activeDownloads.containsKey(downloadId)) {
            final updated = _parseProgressUpdate(downloadId, statusData);
            _activeDownloads[downloadId] = updated;

            // Update notification with latest progress
            if (updated.status == DownloadStatus.downloading &&
                updated.progress != null) {
              NotificationService.showDownloadProgress(
                downloadId: downloadId,
                title: updated.identifier,
                description: updated.currentFile ?? 'Downloading files...',
                progress: updated.progress!,
                currentFile: updated.completedFiles,
                totalFiles: updated.totalFiles,
              );
            } else if (updated.status == DownloadStatus.paused &&
                updated.progress != null) {
              NotificationService.showDownloadPaused(
                downloadId: downloadId,
                title: updated.identifier,
                description: updated.currentFile ?? 'Download paused',
                progress: updated.progress!,
              );
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update download statuses: $e');
    }
  }

  /// Handle download progress update from native
  void _handleDownloadProgress(Map<dynamic, dynamic> data) {
    final downloadId = data['downloadId'] as String?;
    if (downloadId == null) return;

    _activeDownloads[downloadId] = _parseProgressUpdate(downloadId, data);
    notifyListeners();
  }

  /// Handle download completion from native
  void _handleDownloadComplete(Map<dynamic, dynamic> data) {
    final downloadId = data['downloadId'] as String?;
    if (downloadId == null) return;

    if (_activeDownloads.containsKey(downloadId)) {
      final completedDownload = _activeDownloads[downloadId]!.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        completedFiles: _activeDownloads[downloadId]!.totalFiles,
      );

      // Update statistics
      _totalFilesDownloaded += completedDownload.totalFiles;
      if (completedDownload.totalBytes != null) {
        _totalBytesDownloaded += completedDownload.totalBytes!;
      }

      // Move to completed downloads
      _completedDownloads[downloadId] = completedDownload;
      _activeDownloads.remove(downloadId);

      // Save to local archive storage (async, non-blocking)
      final files = _downloadFiles[downloadId];
      if (files != null && files.isNotEmpty) {
        _saveToLocalArchive(
          downloadId,
          files,
          '/storage/emulated/0/Download/ia-get/$downloadId',
        );
      }

      // Show completion notification
      NotificationService.showDownloadComplete(
        downloadId: downloadId,
        title: completedDownload.identifier,
        archiveName: completedDownload.identifier,
        fileCount: completedDownload.totalFiles,
      );

      notifyListeners();

      // Process queue if there are pending downloads
      _processQueue();

      // Remove from completed after a longer delay
      Timer(const Duration(minutes: 5), () {
        _completedDownloads.remove(downloadId);
        notifyListeners();
      });
    }
  }

  /// Handle download error from native
  void _handleDownloadError(Map<dynamic, dynamic> data) {
    final downloadId = data['downloadId'] as String?;
    final errorMessage = data['error'] as String?;
    if (downloadId == null) return;

    if (_activeDownloads.containsKey(downloadId)) {
      final failedDownload = _activeDownloads[downloadId]!.copyWith(
        status: DownloadStatus.error,
        errorMessage: errorMessage,
      );

      _activeDownloads[downloadId] = failedDownload;

      // Show error notification
      NotificationService.showDownloadError(
        downloadId: downloadId,
        title: failedDownload.identifier,
        errorMessage: errorMessage ?? 'Unknown error',
      );

      notifyListeners();
    }
  }

  /// Retry failed downloads automatically
  Future<void> _retryFailedDownloads() async {
    final failedDownloads = _activeDownloads.entries
        .where((entry) => entry.value.status == DownloadStatus.error)
        .toList();

    for (final entry in failedDownloads) {
      final download = entry.value;

      // Check if we should retry based on retry count and max retries
      if (download.retryCount < _maxRetries) {
        // Skip retrying for certain unrecoverable errors
        if (download.errorMessage != null &&
            (download.errorMessage!.contains('Insufficient space') ||
                download.errorMessage!.contains('Permission denied') ||
                download.errorMessage!.contains('Not found'))) {
          debugPrint(
            'Skipping retry for unrecoverable error: ${download.errorMessage}',
          );
          continue;
        }

        // Increment retry count
        final updatedDownload = download.copyWith(
          retryCount: download.retryCount + 1,
          status: DownloadStatus.queued,
        );
        _activeDownloads[entry.key] = updatedDownload;

        debugPrint(
          'Auto-retrying failed download: ${download.identifier} (attempt ${download.retryCount + 1}/$_maxRetries)',
        );
        await resumeDownload(entry.key);
      } else {
        debugPrint('Max retries reached for ${download.identifier}, giving up');
        // Mark as permanently failed
        final updatedDownload = download.copyWith(
          errorMessage: '${download.errorMessage} (Max retries: $_maxRetries)',
        );
        _activeDownloads[entry.key] = updatedDownload;
      }
    }

    notifyListeners();
  }

  /// Process the download queue
  Future<void> _processQueue() async {
    if (_downloadQueue.isEmpty) return;
    if (_activeDownloads.length >= _maxConcurrentDownloads) return;

    final toProcess = _maxConcurrentDownloads - _activeDownloads.length;
    for (int i = 0; i < toProcess && _downloadQueue.isNotEmpty; i++) {
      final downloadId = _downloadQueue.removeAt(0);
      // Resume the queued download
      await resumeDownload(downloadId);
    }

    notifyListeners();
  }

  /// Parse progress update from native data
  DownloadProgress _parseProgressUpdate(
    String downloadId,
    Map<dynamic, dynamic> data,
  ) {
    final existing = _activeDownloads[downloadId];
    if (existing == null) {
      return DownloadProgress(
        downloadId: downloadId,
        identifier: data['identifier'] as String? ?? '',
        totalFiles: data['totalFiles'] as int? ?? 0,
        status: DownloadStatus.queued,
      );
    }

    return existing.copyWith(
      progress: (data['progress'] as num?)?.toDouble(),
      completedFiles: data['completedFiles'] as int?,
      currentFile: data['currentFile'] as String?,
      downloadedBytes: data['downloadedBytes'] as int?,
      totalBytes: data['totalBytes'] as int?,
      transferSpeed: data['transferSpeed'] as double?,
      status: _parseDownloadStatus(data['status'] as String?),
    );
  }

  /// Parse download status from string
  DownloadStatus _parseDownloadStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'queued':
        return DownloadStatus.queued;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'error':
        return DownloadStatus.error;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.queued;
    }
  }

  /// Clear all completed downloads
  void clearCompletedDownloads() {
    _completedDownloads.clear();
    notifyListeners();
  }

  /// Cancel all active downloads
  Future<void> cancelAllDownloads() async {
    final downloadIds = _activeDownloads.keys.toList();
    for (final id in downloadIds) {
      await cancelDownload(id);
    }
    _downloadQueue.clear();
    notifyListeners();
  }

  /// Pause all active downloads
  Future<void> pauseAllDownloads() async {
    final downloadIds = _activeDownloads.entries
        .where((entry) => entry.value.status == DownloadStatus.downloading)
        .map((entry) => entry.key)
        .toList();

    for (final id in downloadIds) {
      await pauseDownload(id);
    }
  }

  /// Resume all paused downloads
  Future<void> resumeAllDownloads() async {
    final downloadIds = _activeDownloads.entries
        .where((entry) => entry.value.status == DownloadStatus.paused)
        .map((entry) => entry.key)
        .toList();

    for (final id in downloadIds) {
      await resumeDownload(id);
    }
  }

  /// Get download statistics
  DownloadStatistics getStatistics() {
    final activeBytes = _activeDownloads.values.fold<int>(
      0,
      (sum, download) => sum + (download.downloadedBytes ?? 0),
    );
    final averageSpeed =
        _activeDownloads.values
            .where((d) => d.transferSpeed != null)
            .fold<double>(0, (sum, d) => sum + d.transferSpeed!) /
        (_activeDownloads.values
            .where((d) => d.transferSpeed != null)
            .length
            .toDouble()
            .clamp(1, double.infinity));

    return DownloadStatistics(
      activeDownloads: activeDownloadCount,
      completedDownloads: completedDownloadCount,
      queuedDownloads: queuedDownloadCount,
      totalFiles: _totalFilesDownloaded,
      totalBytes: _totalBytesDownloaded,
      activeBytesDownloaded: activeBytes,
      averageSpeed: averageSpeed,
      sessionDurationSeconds: sessionDuration?.inSeconds ?? 0,
    );
  }

  /// Compute download statistics in a background isolate
  /// This is useful for processing large download histories without blocking the UI
  static Future<Map<String, dynamic>> computeDetailedStatistics(
    List<DownloadProgress> downloads,
  ) async {
    return await Isolate.run(() => _computeStatisticsIsolate(downloads));
  }

  /// Isolate function to compute detailed statistics
  static Map<String, dynamic> _computeStatisticsIsolate(
    List<DownloadProgress> downloads,
  ) {
    // Compute various statistics without blocking the main thread
    final totalDownloads = downloads.length;
    final completedDownloads = downloads
        .where((d) => d.status == DownloadStatus.completed)
        .length;
    final failedDownloads = downloads
        .where((d) => d.status == DownloadStatus.error)
        .length;

    // Calculate success rate
    final successRate = totalDownloads > 0
        ? (completedDownloads / totalDownloads * 100)
        : 0.0;

    // Calculate total data transferred
    final totalBytes = downloads
        .where((d) => d.downloadedBytes != null)
        .fold<int>(0, (sum, d) => sum + (d.downloadedBytes ?? 0));

    // Calculate average speed from completed downloads
    final downloadsWithSpeed = downloads
        .where((d) => d.transferSpeed != null && d.transferSpeed! > 0)
        .toList();
    final avgSpeed = downloadsWithSpeed.isNotEmpty
        ? downloadsWithSpeed.fold<double>(
                0,
                (sum, d) => sum + d.transferSpeed!,
              ) /
              downloadsWithSpeed.length
        : 0.0;

    // Calculate average file count per download
    final avgFilesPerDownload = downloads.isNotEmpty
        ? downloads.fold<int>(0, (sum, d) => sum + d.totalFiles) /
              downloads.length
        : 0.0;

    // Count downloads that needed retries
    final downloadsWithRetries = downloads
        .where((d) => d.retryCount > 0)
        .length;
    final retryRate = totalDownloads > 0
        ? (downloadsWithRetries / totalDownloads * 100)
        : 0.0;

    return {
      'totalDownloads': totalDownloads,
      'completedDownloads': completedDownloads,
      'failedDownloads': failedDownloads,
      'successRate': successRate,
      'totalBytes': totalBytes,
      'averageSpeed': avgSpeed,
      'averageFilesPerDownload': avgFilesPerDownload,
      'downloadsWithRetries': downloadsWithRetries,
      'retryRate': retryRate,
    };
  }

  /// Save completed download to local archive storage
  Future<void> _saveToLocalArchive(
    String identifier,
    List<String> downloadedFiles,
    String localPath,
  ) async {
    if (_archiveStorage == null) {
      debugPrint('Archive storage not set, skipping save');
      return;
    }

    try {
      final metadata = _downloadMetadata[identifier];
      if (metadata == null) {
        debugPrint('No metadata found for $identifier, cannot save to archive');
        return;
      }

      final archive = DownloadedArchive.fromMetadata(
        metadata: metadata,
        localPath: localPath,
        downloadedFileNames: downloadedFiles,
      );

      await _archiveStorage!.saveArchive(archive);
      debugPrint('Saved archive $identifier to local storage');

      // Clean up metadata cache
      _downloadMetadata.remove(identifier);
    } catch (e) {
      debugPrint('Failed to save archive $identifier: $e');
    }
  }
}
