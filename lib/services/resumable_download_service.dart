import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/download_task.dart';
import '../models/download_progress.dart';
import '../database/database_helper.dart';

/// Thrown when a download is stopped mid-stream (user pause/cancel or
/// service disposal). Replaces dio's DioExceptionType.cancel, which this
/// service previously branched on; the status handling below is unchanged.
class _DownloadCancelled implements Exception {
  final String reason;
  _DownloadCancelled(this.reason);

  @override
  String toString() => reason;
}

/// Service for handling resumable downloads with HTTP Range request support
///
/// Uses package:http (the same stack as ia_http_client/archive_service) so
/// the app ships a single HTTP implementation. Range resume, cancel, and
/// receive-timeout behavior are preserved from the previous dio-based
/// version:
/// - Resume interrupted downloads (HTTP Range + ETag verification)
/// - Progress persistence across app restarts
/// - Automatic retry with exponential backoff
/// - Cancellation that surfaces user intent (pause vs cancel) correctly
class ResumableDownloadService {
  static const _userAgent =
      'InternetArchiveHelper/1.9.0 (+https://github.com/Gameaday/IA-Helper)';

  final http.Client _client;
  final DatabaseHelper _db;

  // Active download tracking: a task is active iff it has an entry here.
  // The value is the cancel request flag, checked between stream chunks.
  final Map<String, bool> _cancelRequested = {};
  final Map<String, DownloadProgress> _progressMap = {};

  // User intent for cancel exceptions: a user pause/cancel surfaces as a
  // _DownloadCancelled and must NOT be recorded as an error (it used
  // to burn a retry each time; five pauses permanently killed a task)
  final Set<String> _userPaused = {};
  final Set<String> _userCancelled = {};

  // Callbacks
  final void Function(String taskId, DownloadProgress progress)? onProgress;
  final void Function(String taskId, DownloadTask task)? onComplete;
  final void Function(String taskId, String error)? onError;

  ResumableDownloadService({
    http.Client? client,
    DatabaseHelper? db,
    this.onProgress,
    this.onComplete,
    this.onError,
  }) : _client = client ?? http.Client(),
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

      // Register as active; clear stale user-intent flags from any
      // previous run
      _cancelRequested[task.id] = false;
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

      final request = http.Request('GET', Uri.parse(task.url))
        ..headers['User-Agent'] = _userAgent;
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      // No events for 5 minutes = stalled transfer; mirrors the old
      // receiveTimeout. The initial send gets a shorter connect timeout.
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      // If we sent a Range request but the server ignored it (status 200),
      // appending the full body to the partial file would corrupt it.
      // Delete the partial file and rewrite from byte 0.
      int effectiveStart = startByte;
      if (startByte > 0 && response.statusCode == 200) {
        await file.delete();
        effectiveStart = 0;
        task = task.copyWith(partialBytes: 0);
        await _db.updateDownloadTask(task);
      }

      // Track download progress
      int receivedBytes = effectiveStart;
      int lastPersistedBytes = effectiveStart;
      final startTime = DateTime.now();

      final sink = file.openWrite(
        mode: effectiveStart > 0 ? FileMode.append : FileMode.write,
      );

      // How much is left, for progress: Content-Range gives it for 206;
      // fall back to the known task size when the server sends no length.
      final contentLength = response.contentLength ?? -1;

      try {
        await for (final chunk
            in response.stream.timeout(const Duration(minutes: 5))) {
          if (_cancelRequested[task.id] == true) {
            throw _DownloadCancelled('Download cancelled');
          }
          sink.add(chunk);
          receivedBytes += chunk.length;

          final int totalBytes;
          if (effectiveStart > 0 && contentLength > 0) {
            totalBytes = effectiveStart + contentLength;
          } else if (contentLength > 0) {
            totalBytes = contentLength;
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
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // Get ETag from response for future resume
      final responseETag = response.headers['etag'];

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
      _cancelRequested.remove(task.id);
      _progressMap.remove(task.id);

      return task;
    } catch (e) {
      // Handle errors
      String errorMessage = e.toString();

      if (e is _DownloadCancelled) {
        errorMessage = e.reason;
      } else if (e is TimeoutException) {
        errorMessage = 'Receive timeout';
      } else if (e is http.ClientException) {
        errorMessage = 'Network error';
      }

      // A user-initiated pause/cancel is not an error: persist the intent
      // status without burning a retry and without invoking onError
      if (e is _DownloadCancelled &&
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
        _cancelRequested.remove(task.id);
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
      _cancelRequested.remove(task.id);
      _progressMap.remove(task.id);

      rethrow;
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String taskId) async {
    if (_cancelRequested.containsKey(taskId)) {
      _userPaused.add(taskId);
      _cancelRequested[taskId] = true;
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
    if (_cancelRequested.containsKey(taskId)) {
      _userCancelled.add(taskId);
      _cancelRequested[taskId] = true;
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

    _cancelRequested.remove(taskId);
    _progressMap.remove(taskId);
  }

  /// Get current progress for a task
  DownloadProgress? getProgress(String taskId) {
    return _progressMap[taskId];
  }

  /// Verify if file has changed on server using ETag
  Future<String?> _verifyETag(String url, String expectedETag) async {
    try {
      final request = http.Request('HEAD', Uri.parse(url))
        ..headers['User-Agent'] = _userAgent;
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));

      return response.headers['etag'];
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
    // Request cancellation of all active downloads (no user-intent flags
    // are set, so they surface as errors, same as the previous CancelToken
    // behavior). The flags stay in the map - unlike dio's CancelToken the
    // flag lives here, and each in-flight loop removes its own entry when
    // it unwinds; clearing the map would cancel nothing.
    for (final id in _cancelRequested.keys.toList()) {
      _cancelRequested[id] = true;
    }
    _progressMap.clear();
    _client.close();
  }
}
