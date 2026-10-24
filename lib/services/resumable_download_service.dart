import 'dart:io';
import 'package:dio/dio.dart';
import '../models/download_task.dart';
import '../models/download_progress.dart';
import '../database/database_helper.dart';

/// Service for handling resumable downloads with HTTP Range request support
///
/// Features:
/// - Resume interrupted downloads
/// - ETag verification to detect file changes
/// - Progress persistence across app restarts
/// - Automatic retry with exponential backoff
/// - Bandwidth throttling support
class ResumableDownloadService {
  final Dio _dio;
  final DatabaseHelper _db;

  // Active download tracking
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, DownloadProgress> _progressMap = {};

  // User intent for cancel exceptions: a user pause/cancel surfaces as a
  // DioExceptionType.cancel and must NOT be recorded as an error (it used
  // to burn a retry each time; five pauses permanently killed a task)
  final Set<String> _userPaused = {};
  final Set<String> _userCancelled = {};

  // Callbacks
  final void Function(String taskId, DownloadProgress progress)? onProgress;
  final void Function(String taskId, DownloadTask task)? onComplete;
  final void Function(String taskId, String error)? onError;

  ResumableDownloadService({
    Dio? dio,
    DatabaseHelper? db,
    this.onProgress,
    this.onComplete,
    this.onError,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                // Archive.org asks clients to identify themselves; this
                // client previously sent no User-Agent at all
                headers: {
                  'User-Agent':
                      'InternetArchiveHelper/1.7.1 (+https://github.com/Gameaday/IA-Helper)',
                },
              ),
            ),
       _db = db ?? DatabaseHelper.instance;

  /// Start or resume a download task
  ///
  /// Returns the final DownloadTask on completion or throws on error
  Future<DownloadTask> downloadTask(DownloadTask task) async {
    try {
      // Update task status to downloading
      task = task.copyWith(
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      );
      await _db.updateDownloadTask(task);

      // Create cancel token for this task; clear stale user-intent flags
      // from any previous run
      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;
      _userPaused.remove(task.id);
      _userCancelled.remove(task.id);

      // Check for existing partial file
      final file = File(task.savePath);
      int startByte = 0;
      String? etag;

      if (await file.exists()) {
        startByte = await file.length();

        // Verify file hasn't changed on server
        if (task.etag != null) {
          etag = await _verifyETag(task.url, task.etag!);

          if (etag != task.etag) {
            // File changed on server, start fresh
            await file.delete();
            startByte = 0;
            task = task.copyWith(partialBytes: 0, etag: etag);
            await _db.updateDownloadTask(task);
          }
        }
      } else {
        // Create parent directories if needed
        await file.parent.create(recursive: true);
      }

      // Set up headers for range request
      final headers = <String, dynamic>{};
      if (startByte > 0) {
        headers['Range'] = 'bytes=$startByte-';
      }

      // Track download progress
      int receivedBytes = startByte;
      int lastPersistedBytes = startByte;
      final startTime = DateTime.now();

      // Download with progress tracking
      final response = await _dio.download(
        task.url,
        task.savePath,
        options: Options(
          headers: headers,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          receivedBytes = startByte + received;

          // Calculate progress. When resuming (HTTP 206), dio's [total] is
          // the REMAINING bytes, so the real size is startByte + total. Fall
          // back to the known task size when the server reports no length.
          final int totalBytes;
          if (total > 0) {
            totalBytes = startByte + total;
          } else if (task.totalBytes > 0) {
            totalBytes = task.totalBytes;
          } else {
            totalBytes = 0;
          }
          final progress = DownloadProgress(
            downloadId: task.id,
            identifier: task.identifier,
            totalBytes: totalBytes,
            downloadedBytes: receivedBytes,
            totalFiles: 1,
            currentFile: task.fileName,
            status: DownloadStatus.downloading,
            startTime: startTime,
          );

          _progressMap[task.id] = progress;
          onProgress?.call(task.id, progress);

          // Periodically save progress to the database. Persist every 5 MB:
          // the old byte-exact modulo check almost never fired with chunked
          // progress callbacks, so partialBytes was rarely saved.
          if (receivedBytes - lastPersistedBytes >= 5 * 1024 * 1024) {
            lastPersistedBytes = receivedBytes;
            _db.updateDownloadTask(task.copyWith(partialBytes: receivedBytes));
          }
        },
        deleteOnError: false, // Keep partial file on error
        cancelToken: cancelToken,
      );

      // If we sent a Range request but the server ignored it (status 200),
      // dio appended the full response body to our partial file, which
      // corrupts it. Delete the partial file and restart from byte 0.
      if (startByte > 0 && response.statusCode == 200) {
        await file.delete();
        _cancelTokens.remove(task.id);
        _progressMap.remove(task.id);
        return downloadTask(task.copyWith(partialBytes: 0));
      }

      // Download complete
      if (response.statusCode == 200 || response.statusCode == 206) {
        // Get ETag from response for future resume
        final responseETag = response.headers.value('etag');

        // Verify file size if known
        if (task.totalBytes > 0) {
          final fileSize = await file.length();
          if (fileSize != task.totalBytes) {
            throw Exception(
              'Downloaded file size ($fileSize) does not match expected size (${task.totalBytes})',
            );
          }
        }

        // Update task as completed
        task = task.copyWith(
          status: DownloadStatus.completed,
          completedAt: DateTime.now(),
          partialBytes: receivedBytes,
          etag: responseETag,
        );
        await _db.updateDownloadTask(task);

        // Notify completion
        onComplete?.call(task.id, task);

        // Cleanup
        _cancelTokens.remove(task.id);
        _progressMap.remove(task.id);

        return task;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      String errorMessage = e.toString();

      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          errorMessage = 'Download cancelled';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout';
        } else {
          errorMessage = e.message ?? 'Network error';
        }
      }

      // A user-initiated pause/cancel is not an error: persist the intent
      // status without burning a retry and without invoking onError
      if (e is DioException &&
          e.type == DioExceptionType.cancel &&
          (_userPaused.contains(task.id) ||
              _userCancelled.contains(task.id))) {
        final pausedIntent = _userPaused.remove(task.id);
        _userCancelled.remove(task.id);

        final file = File(task.savePath);
        final partialBytes = await file.exists() ? await file.length() : 0;

        task = task.copyWith(
          status: pausedIntent
              ? DownloadStatus.paused
              : DownloadStatus.cancelled,
          partialBytes: partialBytes,
        );
        await _db.updateDownloadTask(task);

        // Cleanup
        _cancelTokens.remove(task.id);
        _progressMap.remove(task.id);

        return task;
      }

      // Update task status
      final file = File(task.savePath);
      final partialBytes = await file.exists() ? await file.length() : 0;

      task = task.copyWith(
        status: DownloadStatus.error,
        errorMessage: errorMessage,
        partialBytes: partialBytes,
        retryCount: task.retryCount + 1,
      );
      await _db.updateDownloadTask(task);

      // Notify error
      onError?.call(task.id, errorMessage);

      // Cleanup
      _cancelTokens.remove(task.id);
      _progressMap.remove(task.id);

      rethrow;
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String taskId) async {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      _userPaused.add(taskId);
      cancelToken.cancel('Paused by user');
    }

    // Update task status in database
    final task = await _db.getDownloadTask(taskId);
    if (task != null) {
      final file = File(task.savePath);
      final partialBytes = await file.exists() ? await file.length() : 0;

      await _db.updateDownloadTask(
        task.copyWith(
          status: DownloadStatus.paused,
          partialBytes: partialBytes,
        ),
      );
    }
  }

  /// Resume a paused download
  Future<DownloadTask> resumeDownload(String taskId) async {
    final task = await _db.getDownloadTask(taskId);
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    if (task.status != DownloadStatus.paused) {
      throw Exception('Task is not paused: ${task.status}');
    }

    _userPaused.remove(taskId);
    return downloadTask(task);
  }

  /// Cancel a download and optionally delete the partial file
  Future<void> cancelDownload(
    String taskId, {
    bool deletePartialFile = false,
  }) async {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      _userCancelled.add(taskId);
      cancelToken.cancel('Cancelled by user');
    }

    final task = await _db.getDownloadTask(taskId);
    if (task != null) {
      // Delete partial file if requested
      if (deletePartialFile) {
        final file = File(task.savePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Update task status
      await _db.updateDownloadTask(
        task.copyWith(status: DownloadStatus.cancelled),
      );
    }

    _cancelTokens.remove(taskId);
    _progressMap.remove(taskId);
  }

  /// Get current progress for a task
  DownloadProgress? getProgress(String taskId) {
    return _progressMap[taskId];
  }

  /// Verify if file has changed on server using ETag
  Future<String?> _verifyETag(String url, String expectedETag) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      return response.headers.value('etag');
    } catch (e) {
      // If HEAD request fails, assume file hasn't changed
      return expectedETag;
    }
  }

  /// Retry a failed download with exponential backoff
  Future<DownloadTask> retryDownload(String taskId) async {
    final task = await _db.getDownloadTask(taskId);
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    if (task.status != DownloadStatus.error) {
      throw Exception('Task is not in error state: ${task.status}');
    }

    // Calculate backoff delay based on retry count
    final delay = Duration(seconds: 2 << task.retryCount.clamp(0, 5));
    await Future.delayed(delay);

    return downloadTask(task);
  }

  /// Clean up resources
  void dispose() {
    // Cancel all active downloads
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) {
        token.cancel('Service disposed');
      }
    }
    _cancelTokens.clear();
    _progressMap.clear();
  }
}
