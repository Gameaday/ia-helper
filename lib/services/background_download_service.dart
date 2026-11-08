import 'dart:async';
import 'dart:io';
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
import 'archive_url_service.dart';
import 'download_queue_store.dart';
import 'download_retry_policy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/file_utils.dart';
import '../utils/permission_utils.dart';

/// Metrics for tracking download operations
class DownloadMetrics {
  int starts = 0;
  int completions = 0;
  int failures = 0;
  int pauses = 0;
  int resumes = 0;
  int cancellations = 0;
  int retries = 0;
  int queueOperations = 0;

  @override
  String toString() {
    return 'DownloadMetrics('
        'starts: $starts, '
        'completions: $completions, '
        'failures: $failures, '
        'pauses: $pauses, '
        'resumes: $resumes, '
        'cancellations: $cancellations, '
        'retries: $retries, '
        'queueOperations: $queueOperations'
        ')';
  }
}

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

  // Pure-Dart pause/cancel/resume state (the previous implementation called
  // native methods that were never implemented on the Kotlin side, so the
  // buttons did nothing)
  final Map<String, CancellationToken> _cancelTokens = {};
  final Map<String, String> _downloadPaths = {};
  final Map<String, Set<String>> _completedFileNames = {};
  final Map<String, int> _lastProgressNotificationMs = {};
  int _lastProgressUiNotifyMs = 0;
  final Set<String> _pausedDownloads = {};
  Timer? _retryTimer;
  bool _isInitialized = false;
  int _maxConcurrentDownloads = 3;
  int _maxRetries = 3;

  /// Retry policy (#83): bounded attempts, exponential backoff + jitter.
  final DownloadRetryPolicy _retryPolicy = DownloadRetryPolicy();

  /// Earliest time each download may be retried again (backoff window).
  final Map<String, DateTime> _nextRetryAt = {};

  /// Queue persistence (#84): survives app/OS kills so the queue can be
  /// restored on next launch.
  final DownloadQueueStore _queueStore = DownloadQueueStore.instance;

  /// Whether the device currently has a usable connection (#85). Gates the
  /// retry sweep and queue processing; drives pause/resume on change.
  @visibleForTesting
  bool isOnline = true;

  /// Downloads paused because connectivity dropped (#85). Only these are
  /// auto-resumed on reconnect - user-paused downloads stay paused.
  final Set<String> _connectivityPausedDownloads = {};

  /// Connectivity stream subscription (#85); cancelled in [dispose].
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Test seam (#85): when true, resume paths skip the real network call.
  @visibleForTesting
  bool debugDisableNetworkRestarts = false;
  LocalArchiveStorage? _archiveStorage;
  final ArchiveUrlService _urlService = ArchiveUrlService();

  // Metrics tracking
  final DownloadMetrics metrics = DownloadMetrics();

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
    // Captured when the download was started
    return _downloadPaths[downloadId];
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

      // Connectivity-aware pause/resume (#85): resolve the initial state
      // and subscribe before restoring the persisted queue, so a device
      // that starts offline restores the queue without auto-starting it.
      try {
        final results = await Connectivity().checkConnectivity();
        isOnline = results.any((r) => r != ConnectivityResult.none);
      } catch (e) {
        debugPrint('Failed to check initial connectivity: $e');
      }
      _connectivitySub ??= Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object e) => debugPrint('Connectivity stream error: $e'),
      );

      // Reload the queue persisted before any app/OS kill (#84)
      await restorePersistedQueue();

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
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
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

      // Track metrics
      metrics.starts++;

      // Store metadata and files for later use
      // #92: ask for POST_NOTIFICATIONS in context - the first download
      // of a session triggers the Android 13+ system dialog; later calls
      // just re-check the grant without prompting. Never asked at launch.
      unawaited(PermissionUtils.requestNotificationPermission());

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

      if (kDebugMode) {
        debugPrint(
          '[BackgroundDownloadService] Started download: $identifier (${selectedFiles.length} files)',
        );
      }

      notifyListeners();

      // Persist the queued entry: a force-stop from this moment on is
      // recoverable on next launch (#84)
      _persistDownload(downloadId);

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
      metrics.failures++;
      if (kDebugMode) {
        debugPrint('[BackgroundDownloadService] Failed to start download: $e');
      }
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
        _persistDownload(downloadId);
      }

      // Use the InternetArchiveApi to download files
      final api = InternetArchiveApi();

      // Pure-Dart pause/cancel: the api's download loop checks this token
      // between chunks (no native WorkManager involved)
      final cancellationToken = CancellationToken();
      _cancelTokens[downloadId] = cancellationToken;
      _downloadPaths[downloadId] = downloadPath;

      // Per-archive subfolder: <downloadPath>/<identifier>/<file>. Prevents
      // cross-archive name collisions and matches the layout the file list
      // widget expects.
      final archiveDir = '$downloadPath/$identifier';
      final completedFileNames = _completedFileNames.putIfAbsent(
        downloadId,
        () => <String>{},
      );

      // Files that failed this run (#83): drives the partial-failure error
      // status so the bounded retry sweep re-attempts just those files.
      final failedFiles = <String>{};

      int completedFiles = 0;
      int totalDownloadedBytes = 0;
      DateTime? lastUpdateTime;
      int lastDownloadedBytes = 0;
      _lastProgressNotificationMs[downloadId] ??= 0;

      for (final fileName in selectedFiles) {
        // Files that already finished during a previous (paused) run are
        // skipped on resume
        if (completedFileNames.contains(fileName)) {
          completedFiles++;
          continue;
        }

        try {
          final fileUrl = _urlService.getDownloadUrl(identifier, fileName);
          // Archive-served file names are untrusted: route through safeJoin
          final filePath = FileUtils.safeJoin(archiveDir, fileName);
          final fileStartBytes = totalDownloadedBytes;
          int currentFileBytes = 0;

          // Bytes already on disk from a paused/interrupted run: the API's
          // progress callback reports the FULL file length (resumed prefix
          // included), so subtract it to keep run totals honest (#83).
          final existingFile = File(filePath);
          final partialOnDisk = await existingFile.exists()
              ? await existingFile.length()
              : 0;

          // Download file using the API
          await api.downloadFile(
            fileUrl,
            filePath,
            cancellationToken: cancellationToken,
            onProgress: (received, total) {
              // Update progress with proper statistics
              if (_activeDownloads.containsKey(downloadId)) {
                final newBytes =
                    received > partialOnDisk ? received - partialOnDisk : 0;
                currentFileBytes = newBytes;
                final now = DateTime.now();
                final currentTotalBytes = fileStartBytes + newBytes;

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
                // Coalesce UI notifications to ~4 Hz: rebuilding on every
                // progress callback starves the UI thread on fast links.
                final nowMs = now.millisecondsSinceEpoch;
                if (nowMs - _lastProgressUiNotifyMs >= 250) {
                  _lastProgressUiNotifyMs = nowMs;
                  notifyListeners();
                }

                // Throttled progress notification (at most one per second)
                if (nowMs - _lastProgressNotificationMs[downloadId]! >=
                    1000) {
                  _lastProgressNotificationMs[downloadId] = nowMs;
                  NotificationService.showDownloadProgress(
                    downloadId: downloadId,
                    title: identifier,
                    description: fileName,
                    progress: overallProgress,
                    currentFile: completedFiles,
                    totalFiles: selectedFiles.length,
                  );
                }
              }
            },
          );
          // Checksum verification (#83): archive.org metadata carries md5
          // and sha1 per file; a corrupt download must be detected and
          // re-fetched, never surfaced as a completed file.
          if (!await _verifyFileChecksum(downloadId, fileName, filePath)) {
            // Delete the corrupt file so a retry re-fetches from byte 0
            if (await existingFile.exists()) {
              await existingFile.delete();
            }
            throw Exception(
              'Checksum mismatch (corrupt download): $fileName',
            );
          }

          completedFiles++;
          completedFileNames.add(fileName);
          // Persist the completed-file set so a mid-archive kill resumes
          // with exactly these files skipped (#84)
          _persistDownload(downloadId);
          // Track bytes for honest statistics
          totalDownloadedBytes += currentFileBytes;

          // Update completed count
          if (_activeDownloads.containsKey(downloadId)) {
            _activeDownloads[downloadId] =
                _activeDownloads[downloadId]!.copyWith(
              completedFiles: completedFiles,
              currentFileProgress: 0,
              currentFile: null,
            );
            notifyListeners();
          }
        } catch (e) {
          if (cancellationToken.isCancelled) {
            // Pause/cancel: stop the file loop; the finalize block below
            // keeps the status set by pause/cancel. The partial file stays
            // on disk - resume continues from its offset (#83).
            break;
          }
          debugPrint('Failed to download file $fileName: $e');
          failedFiles.add(fileName);
          // Continue with next file even if one fails; the finalize block
          // below reports partial failure instead of a bogus "completed"
        }
      }

      // User pause/cancel: the pause/cancel methods already set the final
      // status; never overwrite it with "completed"
      if (cancellationToken.isCancelled) {
        _cancelTokens.remove(downloadId);
        _lastProgressNotificationMs.remove(downloadId);
        return;
      }

      // Every file failed: report an error instead of "completed"
      if (completedFiles == 0) {
        if (_activeDownloads.containsKey(downloadId)) {
          metrics.failures++;
          final failed = _activeDownloads[downloadId]!;
          _activeDownloads[downloadId] = failed.copyWith(
            status: DownloadStatus.error,
            errorMessage: 'All file downloads failed',
          );
          _cancelTokens.remove(downloadId);
          _completedFileNames.remove(downloadId);
          _lastProgressNotificationMs.remove(downloadId);
          _nextRetryAt.remove(downloadId);
          NotificationService.showDownloadError(
            downloadId: downloadId,
            title: failed.identifier,
            errorMessage: 'All file downloads failed',
          );
          notifyListeners();
          _persistDownload(downloadId);
        }
        return;
      }

      // Partial failure (#83): some files failed but others completed.
      // Surface an error status so the bounded retry sweep re-attempts
      // just the failures (completed files are skipped via
      // _completedFileNames); the downloaded files remain on disk.
      if (failedFiles.isNotEmpty) {
        if (_activeDownloads.containsKey(downloadId)) {
          metrics.failures++;
          final failed = _activeDownloads[downloadId]!;
          final sample = failedFiles.take(3).join(', ');
          final suffix = failedFiles.length > 3 ? ', ...' : '';
          _activeDownloads[downloadId] = failed.copyWith(
            status: DownloadStatus.error,
            errorMessage:
                '${failedFiles.length} of ${selectedFiles.length} files failed ($sample$suffix)',
          );
          _cancelTokens.remove(downloadId);
          _lastProgressNotificationMs.remove(downloadId);
          notifyListeners();
          _persistDownload(downloadId);
        }
        return;
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
        _totalBytesDownloaded += totalDownloadedBytes;

        // Show completion notification
        NotificationService.showDownloadComplete(
          downloadId: downloadId,
          title: download.identifier,
          archiveName: download.identifier,
          fileCount: selectedFiles.length,
        );

        // Save to local archive storage
        await _saveToLocalArchive(downloadId, selectedFiles, archiveDir);

        _cancelTokens.remove(downloadId);
        _completedFileNames.remove(downloadId);
        _lastProgressNotificationMs.remove(downloadId);
        _nextRetryAt.remove(downloadId);
        _queueStore.delete(downloadId);

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
        _cancelTokens.remove(downloadId);
        _completedFileNames.remove(downloadId);
        _lastProgressNotificationMs.remove(downloadId);
        _persistDownload(downloadId);
      }
    }
  }

  /// Cancel a background download
  Future<bool> cancelDownload(String downloadId) async {
    // Pure Dart implementation: cancel via the download's cancellation
    // token. (The previous version called a native method that was never
    // implemented, so cancel silently did nothing.)
    final token = _cancelTokens[downloadId];
    // A paused download no longer holds a token (its run finished); it can
    // still be cancelled from the UI.
    if (token != null) {
      token.cancel();
    } else if (!_activeDownloads.containsKey(downloadId)) {
      return false;
    }

    _cancelTokens.remove(downloadId);
    _pausedDownloads.remove(downloadId);
    _nextRetryAt.remove(downloadId);
    _completedFileNames.remove(downloadId);
    _lastProgressNotificationMs.remove(downloadId);
    _downloadPaths.remove(downloadId);
    _downloadMetadata.remove(downloadId);
    _downloadFiles.remove(downloadId);

    // Drop the persisted queue entry (#84)
    _queueStore.delete(downloadId);

    // Track metrics
    metrics.cancellations++;

    _activeDownloads.remove(downloadId);

    if (kDebugMode) {
      debugPrint(
        '[BackgroundDownloadService] Cancelled download: $downloadId',
      );
    }

    notifyListeners();
    return true;
  }
  /// Pause a background download
  Future<bool> pauseDownload(String downloadId) async {
    // Pure Dart implementation: cancelling the token stops the in-flight
    // file; already-completed files are tracked so resume can skip them.
    final token = _cancelTokens[downloadId];
    if (token == null) return false;

    // Track metrics
    metrics.pauses++;

    _pausedDownloads.add(downloadId);
    token.cancel();

    if (_activeDownloads.containsKey(downloadId)) {
      _activeDownloads[downloadId] = _activeDownloads[downloadId]!.copyWith(
        status: DownloadStatus.paused,
      );

      if (kDebugMode) {
        debugPrint(
          '[BackgroundDownloadService] Paused download: $downloadId',
        );
      }

      notifyListeners();
      _persistDownload(downloadId);
    }

    return true;
  }
  /// Resume a paused download
  Future<bool> resumeDownload(String downloadId) async {
    // Pure Dart implementation: restart the download loop; files that
    // already completed are skipped via _completedFileNames.
    final download = _activeDownloads[downloadId];
    if (download == null) return false;
    if (download.status != DownloadStatus.paused &&
        download.status != DownloadStatus.error &&
        download.status != DownloadStatus.queued) {
      return false;
    }

    final files = _downloadFiles[downloadId];
    final path = _downloadPaths[downloadId];
    if (files == null || path == null) return false;

    // Track metrics
    metrics.resumes++;

    _pausedDownloads.remove(downloadId);

    _activeDownloads[downloadId] = download.copyWith(
      status: DownloadStatus.downloading,
    );

    if (kDebugMode) {
      debugPrint(
        '[BackgroundDownloadService] Resumed download: $downloadId',
      );
    }

    notifyListeners();
    _persistDownload(downloadId);

    // Restart the download
    if (!debugDisableNetworkRestarts) {
      _startDartDownload(
        downloadId: downloadId,
        identifier: download.identifier,
        selectedFiles: files,
        downloadPath: path,
      );
    }

    return true;
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
      // Track metrics
      metrics.completions++;

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

      if (kDebugMode) {
        debugPrint(
          '[BackgroundDownloadService] Completed download: $downloadId '
          '(${completedDownload.totalFiles} files, '
          '${completedDownload.totalBytes != null ? "${(completedDownload.totalBytes! / 1024 / 1024).toStringAsFixed(1)} MB" : "unknown size"})',
        );
      }

      // Save to local archive storage (async, non-blocking)
      final files = _downloadFiles[downloadId];
      final path = _downloadPaths[downloadId];
      if (files != null && files.isNotEmpty && path != null) {
        _saveToLocalArchive(
          downloadId,
          files,
          '$path/$downloadId',
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
      // Track metrics
      metrics.failures++;

      final failedDownload = _activeDownloads[downloadId]!.copyWith(
        status: DownloadStatus.error,
        errorMessage: errorMessage,
      );

      if (kDebugMode) {
        debugPrint(
          '[BackgroundDownloadService] Download failed: $downloadId '
          'Error: ${errorMessage ?? "unknown"}',
        );
      }

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

  /// Connectivity change callback (#85): maps raw results onto
  /// online/offline and forwards to the state machine.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    unawaited(
      handleConnectivityChange(
        online: results.any((r) => r != ConnectivityResult.none),
      ),
    );
  }

  /// Connectivity-aware pause/resume state machine (#85).
  ///
  /// Connection loss pauses in-flight downloads cleanly: the token-cancel
  /// path in the file loop keeps their state paused, so there is no error
  /// status, no retry spam, and partial files stay on disk (#83 resume).
  /// Reconnect auto-resumes only downloads paused by connectivity;
  /// user-paused downloads stay untouched. Failed and queued downloads
  /// get an immediate chance instead of waiting up to 10s for the next
  /// sweep tick.
  @visibleForTesting
  Future<void> handleConnectivityChange({required bool online}) async {
    if (online == isOnline) {
      return; // Ignore duplicate/flapping reports
    }
    isOnline = online;

    if (!online) {
      debugPrint(
        '[BackgroundDownloadService] Connection lost: pausing in-flight '
        'download(s)',
      );
      for (final downloadId in _activeDownloads.keys.toList()) {
        if (_activeDownloads[downloadId]?.status !=
            DownloadStatus.downloading) {
          continue;
        }
        _connectivityPausedDownloads.add(downloadId);
        await pauseDownload(downloadId);
      }
    } else {
      debugPrint(
        '[BackgroundDownloadService] Connection restored: resuming '
        '${_connectivityPausedDownloads.length} download(s)',
      );
      final toResume = _connectivityPausedDownloads.toList();
      _connectivityPausedDownloads.clear();
      for (final downloadId in toResume) {
        if (!_activeDownloads.containsKey(downloadId)) {
          continue; // cancelled while offline
        }
        await resumeDownload(downloadId);
      }
      // Give failed and queued downloads an immediate retry chance
      await _retryFailedDownloads();
      await _processQueue();
    }
  }

  /// Test seam (#85): place a download in a specific state without any
  /// network I/O so the connectivity state machine is unit-testable.
  @visibleForTesting
  void debugSeedDownload({
    required String downloadId,
    required String identifier,
    required List<String> selectedFiles,
    required String downloadPath,
    DownloadStatus status = DownloadStatus.downloading,
    bool queued = false,
    String? errorMessage,
  }) {
    _activeDownloads[downloadId] = DownloadProgress(
      downloadId: downloadId,
      identifier: identifier,
      totalFiles: selectedFiles.length,
      status: status,
      errorMessage: errorMessage,
    );
    _downloadFiles[downloadId] = selectedFiles;
    _downloadPaths[downloadId] = downloadPath;
    if (status == DownloadStatus.downloading) {
      _cancelTokens[downloadId] = CancellationToken();
    }
    if (queued) {
      _downloadQueue.add(downloadId);
    }
  }

  /// Test seam (#85): drive the private retry sweep from tests.
  @visibleForTesting
  Future<void> debugRunRetrySweep() => _retryFailedDownloads();

  /// Test seam (#85): drive the private queue processor from tests.
  @visibleForTesting
  Future<void> debugProcessQueue() => _processQueue();

  /// Retry failed downloads automatically.
  ///
  /// Bounded attempts with exponential backoff + jitter (#83). The sweep
  /// timer runs every 10s, but each download only becomes eligible after
  /// its backoff window. Unrecoverable errors (missing file, auth, out of
  /// space) are never retried and get a clear final message.
  Future<void> _retryFailedDownloads() async {
    // While offline, don't burn retry attempts (#85): the reconnect
    // handler gives failed downloads a fresh chance.
    if (!isOnline) {
      return;
    }

    final failedDownloads = _activeDownloads.entries
        .where((entry) => entry.value.status == DownloadStatus.error)
        .toList();

    for (final entry in failedDownloads) {
      final download = entry.value;

      // Backoff window not elapsed yet - skip this sweep tick
      final nextRetryAt = _nextRetryAt[entry.key];
      if (nextRetryAt != null && DateTime.now().isBefore(nextRetryAt)) {
        continue;
      }

      final retryable = _retryPolicy.shouldRetry(
        download.errorMessage ?? '',
        attempt: download.retryCount,
        maxAttempts: _maxRetries,
      );

      if (!retryable) {
        if (kDebugMode) {
          debugPrint(
            '[BackgroundDownloadService] Not retrying ${download.identifier}: '
            '${download.errorMessage ?? "unknown error"}',
          );
        }
        // Permanent failure: make the final state clear for the UI
        _nextRetryAt.remove(entry.key);
        _activeDownloads[entry.key] = download.copyWith(
          errorMessage:
              '${download.errorMessage ?? "Unknown error"} '
              '(gave up after ${download.retryCount} attempt(s))',
        );
        _persistDownload(entry.key);
        continue;
      }

      // Track retry metric
      metrics.retries++;

      // Schedule the next allowed retry (exponential backoff + jitter)
      _nextRetryAt[entry.key] =
          DateTime.now().add(_retryPolicy.delayFor(download.retryCount));

      // Increment retry count
      final updatedDownload = download.copyWith(
        retryCount: download.retryCount + 1,
        status: DownloadStatus.queued,
      );
      _activeDownloads[entry.key] = updatedDownload;
      _persistDownload(entry.key);

      if (kDebugMode) {
        debugPrint(
          '[BackgroundDownloadService] Auto-retrying failed download: ${download.identifier} '
          '(attempt ${download.retryCount + 1}/$_maxRetries)',
        );
      }

      await resumeDownload(entry.key);
    }

    notifyListeners();
  }

  /// Process the download queue
  Future<void> _processQueue() async {
    if (_downloadQueue.isEmpty) return;
    if (!isOnline) return; // Don't start new downloads while offline (#85)
    if (_activeDownloads.length >= _maxConcurrentDownloads) return;

    // Track queue operations
    metrics.queueOperations++;

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

  /// Verify one downloaded file against the checksums in the archive's IA
  /// metadata (#83). Returns true when the file matches, or when no
  /// checksum is available (nothing to verify).
  Future<bool> _verifyFileChecksum(
    String downloadId,
    String fileName,
    String filePath,
  ) async {
    final metadata = _downloadMetadata[downloadId];
    if (metadata == null) {
      return true;
    }

    ArchiveFile? fileMeta;
    for (final candidate in metadata.files) {
      if (candidate.name == fileName) {
        fileMeta = candidate;
        break;
      }
    }
    if (fileMeta == null) {
      return true;
    }

    final md5Hash = fileMeta.md5;
    if (md5Hash != null && md5Hash.isNotEmpty) {
      return FileUtils.verifyChecksum(filePath, md5Hash, algorithm: 'md5');
    }
    final sha1Hash = fileMeta.sha1;
    if (sha1Hash != null && sha1Hash.isNotEmpty) {
      return FileUtils.verifyChecksum(filePath, sha1Hash, algorithm: 'sha1');
    }
    return true;
  }

  /// Persist one queue entry so an app/OS kill is recoverable (#84).
  /// Fire-and-forget: persistence failures must never break a download.
  Future<void> _persistDownload(String downloadId) async {
    try {
      final progress = _activeDownloads[downloadId];
      if (progress == null) {
        await _queueStore.delete(downloadId);
        return;
      }
      final downloadPath = _downloadPaths[downloadId] ?? '';
      await _queueStore.save(
        PersistedDownload(
          downloadId: downloadId,
          identifier: progress.identifier,
          downloadPath: downloadPath,
          archiveDir: downloadPath.isEmpty
              ? ''
              : '$downloadPath/${progress.identifier}',
          progress: progress,
          selectedFiles: _downloadFiles[downloadId] ?? const [],
          completedFiles: _completedFileNames[downloadId] ?? const {},
          metadata: _downloadMetadata[downloadId],
        ),
      );
    } catch (e) {
      debugPrint('Failed to persist download $downloadId: $e');
    }
  }

  /// Restore downloads persisted before an app/OS kill (#84).
  ///
  /// Recoverable entries come back as PAUSED with their completed-file set
  /// intact: the transfers screen offers Resume, which skips already
  /// completed files and continues partial files from their byte offset
  /// (#83 Range resume). Entries whose download directory no longer exists
  /// (cleared app data) are dropped instead of restored as zombies.
  Future<void> restorePersistedQueue() async {
    try {
      final persisted = await _queueStore.loadRecoverable();
      for (final entry in persisted) {
        if (_activeDownloads.containsKey(entry.downloadId)) continue;

        if (entry.downloadPath.isEmpty) {
          await _queueStore.delete(entry.downloadId);
          continue;
        }
        final dirExists =
            await Directory(entry.archiveDir).exists() ||
                await Directory(entry.downloadPath).exists();
        if (!dirExists) {
          await _queueStore.delete(entry.downloadId);
          continue;
        }

        final wasError = entry.progress.status == DownloadStatus.error;
        _activeDownloads[entry.downloadId] = entry.progress.copyWith(
          status: DownloadStatus.paused,
          errorMessage: wasError
              ? entry.progress.errorMessage
              : 'Interrupted by app restart',
        );
        _downloadFiles[entry.downloadId] = entry.selectedFiles;
        _downloadPaths[entry.downloadId] = entry.downloadPath;
        _completedFileNames[entry.downloadId] = entry.completedFiles;
        if (entry.metadata != null) {
          _downloadMetadata[entry.downloadId] = entry.metadata!;
        }
      }
      if (persisted.isNotEmpty) {
        debugPrint(
          '[BackgroundDownloadService] Restored ${persisted.length} '
          'download(s) after restart',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to restore persisted downloads: $e');
    }
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

  /// Get current metrics
  DownloadMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  void resetMetrics() {
    metrics.starts = 0;
    metrics.completions = 0;
    metrics.failures = 0;
    metrics.pauses = 0;
    metrics.resumes = 0;
    metrics.cancellations = 0;
    metrics.retries = 0;
    metrics.queueOperations = 0;
    if (kDebugMode) {
      debugPrint('[BackgroundDownloadService] Metrics reset');
    }
  }
}

