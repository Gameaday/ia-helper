import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing Android notifications for downloads
///
/// Platform-aware: Works on all platforms (no-op on web via try-catch).
class NotificationService {
  static const _platform = MethodChannel(
    'com.internetarchive.helper/notifications',
  );

  static bool _isInitialized = false;
  static const String _downloadChannelId = 'download_progress';
  static const String _completionChannelId = 'download_completion';

  /// Initialize the notification service
  ///
  /// Works on all platforms. On web, MethodChannel calls are no-ops (caught silently).
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _platform.invokeMethod('initialize', {
        'channels': [
          {
            'id': _downloadChannelId,
            'name': 'Download Progress',
            'description': 'Shows progress of ongoing downloads',
            'importance': 'low', // Less intrusive for progress notifications
            'showBadge': false,
          },
          {
            'id': _completionChannelId,
            'name': 'Download Complete',
            'description': 'Notifications when downloads are completed',
            'importance': 'default',
            'showBadge': true,
          },
        ],
      });

      _isInitialized = true;
    } catch (e) {
      // Silent failure on web (MethodChannel not available)
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
      if (kDebugMode) {
        debugPrint('[NotificationService] Initialize handled: $e');
      }
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      final result = await _platform.invokeMethod('requestPermissions');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Request permissions handled: $e');
      }
      return false;
    }
  }

  /// Check if notification permissions are granted
  static Future<bool> arePermissionsGranted() async {
    try {
      final result = await _platform.invokeMethod('arePermissionsGranted');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Check permissions handled: $e');
      }
      return false;
    }
  }

  /// Show download progress notification
  static Future<void> showDownloadProgress({
    required String downloadId,
    required String title,
    required String description,
    required double progress,
    int? currentFile,
    int? totalFiles,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _platform.invokeMethod('showProgressNotification', {
        'notificationId': downloadId.hashCode,
        'channelId': _downloadChannelId,
        'title': title,
        'description': description,
        'progress': (progress * 100).round(),
        'maxProgress': 100,
        'indeterminate': progress < 0,
        'ongoing': true,
        'cancelable': true,
        'downloadId': downloadId,
        'actions': [
          {'id': 'pause', 'title': 'Pause', 'icon': 'pause'},
          {'id': 'cancel', 'title': 'Cancel', 'icon': 'close'},
        ],
        'extras': {'currentFile': currentFile, 'totalFiles': totalFiles},
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Show progress handled: $e');
      }
    }
  }

  /// Show paused download notification
  static Future<void> showDownloadPaused({
    required String downloadId,
    required String title,
    required String description,
    required double progress,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _platform.invokeMethod('showProgressNotification', {
        'notificationId': downloadId.hashCode,
        'channelId': _downloadChannelId,
        'title': '$title (Paused)',
        'description': description,
        'progress': (progress * 100).round(),
        'maxProgress': 100,
        'indeterminate': false,
        'ongoing': false,
        'cancelable': true,
        'downloadId': downloadId,
        'actions': [
          {'id': 'resume', 'title': 'Resume', 'icon': 'play'},
          {'id': 'cancel', 'title': 'Cancel', 'icon': 'close'},
        ],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Show paused handled: $e');
      }
    }
  }

  /// Show download completion notification
  static Future<void> showDownloadComplete({
    required String downloadId,
    required String title,
    required String archiveName,
    required int fileCount,
    String? downloadPath,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _platform.invokeMethod('showNotification', {
        'notificationId': downloadId.hashCode,
        'channelId': _completionChannelId,
        'title': 'Download Complete',
        'description': '$title - $fileCount files downloaded',
        'largeIcon': 'archive_icon',
        'autoCancel': true,
        'downloadId': downloadId,
        'actions': [
          {'id': 'open_folder', 'title': 'Open Folder', 'icon': 'folder_open'},
          {'id': 'share', 'title': 'Share', 'icon': 'share'},
        ],
        'extras': {
          'downloadPath': downloadPath,
          'archiveName': archiveName,
          'fileCount': fileCount,
        },
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Show complete handled: $e');
      }
    }
  }

  /// Show download error notification
  static Future<void> showDownloadError({
    required String downloadId,
    required String title,
    required String errorMessage,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _platform.invokeMethod('showNotification', {
        'notificationId': downloadId.hashCode,
        'channelId': _completionChannelId,
        'title': 'Download Failed',
        'description': '$title - $errorMessage',
        'largeIcon': 'error_icon',
        'autoCancel': true,
        'priority': 'high',
        'downloadId': downloadId,
        'actions': [
          {'id': 'retry', 'title': 'Retry', 'icon': 'refresh'},
          {'id': 'dismiss', 'title': 'Dismiss', 'icon': 'close'},
        ],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Show error handled: $e');
      }
    }
  }

  /// Cancel/dismiss a notification
  static Future<void> cancelNotification(String downloadId) async {
    try {
      await _platform.invokeMethod('cancelNotification', {
        'notificationId': downloadId.hashCode,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Cancel notification handled: $e');
      }
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _platform.invokeMethod('cancelAllNotifications');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Cancel all handled: $e');
      }
    }
  }

  /// Show a summary notification when multiple downloads are active
  static Future<void> showDownloadSummary({
    required int activeDownloads,
    required int completedDownloads,
    required double averageProgress,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _platform.invokeMethod('showNotification', {
        'notificationId': 'download_summary'.hashCode,
        'channelId': _downloadChannelId,
        'title': 'Downloads in Progress',
        'description': '$activeDownloads active, $completedDownloads completed',
        'progress': (averageProgress * 100).round(),
        'maxProgress': 100,
        'ongoing': true,
        'groupSummary': true,
        'actions': [
          {'id': 'pause_all', 'title': 'Pause All', 'icon': 'pause'},
          {'id': 'open_app', 'title': 'Open App', 'icon': 'app'},
        ],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Show summary handled: $e');
      }
    }
  }

  /// Update app icon badge count (if supported)
  static Future<void> updateBadgeCount(int count) async {
    try {
      await _platform.invokeMethod('updateBadgeCount', {'count': count});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Update badge handled: $e');
      }
    }
  }
}
