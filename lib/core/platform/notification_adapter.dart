import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform adapter for notification functionality
///
/// Provides a consistent notification API across all platforms:
/// - Native (Android): Uses MethodChannel for real Android notifications
/// - Web: No-op implementation (notifications not supported)
///
/// This eliminates platform checks from NotificationService.
abstract class NotificationAdapter {
  /// Initialize the notification system
  Future<void> initialize();

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions();

  /// Show a progress notification
  ///
  /// [notificationId] - Unique ID for this notification
  /// [title] - Notification title
  /// [text] - Notification text
  /// [progress] - Progress value (0-100)
  /// [indeterminate] - Whether to show indeterminate progress
  Future<void> showProgress({
    required int notificationId,
    required String title,
    required String text,
    required int progress,
    bool indeterminate = false,
  });

  /// Update an existing progress notification
  Future<void> updateProgress({
    required int notificationId,
    required int progress,
    String? text,
  });

  /// Show a completion notification
  ///
  /// [notificationId] - Unique ID for this notification
  /// [title] - Notification title
  /// [text] - Notification text
  /// [success] - Whether download was successful
  Future<void> showCompletion({
    required int notificationId,
    required String title,
    required String text,
    required bool success,
  });

  /// Cancel/dismiss a notification
  Future<void> cancelNotification(int notificationId);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Factory constructor that returns the appropriate implementation
  factory NotificationAdapter() {
    if (kIsWeb) {
      return _WebNotificationAdapter();
    }
    return _NativeNotificationAdapter();
  }
}

/// Native (Android/iOS) notification implementation
///
/// Uses MethodChannel to communicate with native Android notification system.
class _NativeNotificationAdapter implements NotificationAdapter {
  static const _platform = MethodChannel(
    'com.internetarchive.helper/notifications',
  );

  static bool _isInitialized = false;
  static const String _downloadChannelId = 'download_progress';
  static const String _completionChannelId = 'download_completion';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _platform.invokeMethod('initialize', {
        'channels': [
          {
            'id': _downloadChannelId,
            'name': 'Download Progress',
            'description': 'Shows progress of ongoing downloads',
            'importance': 'low',
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
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to initialize: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final result = await _platform.invokeMethod('requestPermissions');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to request permissions: $e');
      }
      return false;
    }
  }

  @override
  Future<void> showProgress({
    required int notificationId,
    required String title,
    required String text,
    required int progress,
    bool indeterminate = false,
  }) async {
    try {
      await _platform.invokeMethod('showProgress', {
        'id': notificationId,
        'channelId': _downloadChannelId,
        'title': title,
        'text': text,
        'progress': progress,
        'indeterminate': indeterminate,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to show progress: $e');
      }
    }
  }

  @override
  Future<void> updateProgress({
    required int notificationId,
    required int progress,
    String? text,
  }) async {
    try {
      await _platform.invokeMethod('updateProgress', {
        'id': notificationId,
        'progress': progress,
        if (text != null) 'text': text,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to update progress: $e');
      }
    }
  }

  @override
  Future<void> showCompletion({
    required int notificationId,
    required String title,
    required String text,
    required bool success,
  }) async {
    try {
      await _platform.invokeMethod('showCompletion', {
        'id': notificationId,
        'channelId': _completionChannelId,
        'title': title,
        'text': text,
        'success': success,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to show completion: $e');
      }
    }
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _platform.invokeMethod('cancelNotification', {
        'id': notificationId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to cancel notification: $e');
      }
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _platform.invokeMethod('cancelAllNotifications');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAdapter] Failed to cancel all: $e');
      }
    }
  }
}

/// Web notification implementation
///
/// Provides no-op implementations since Flutter web doesn't support
/// native notifications. All methods succeed silently.
///
/// Future enhancement: Could implement browser Notification API
/// for basic notifications on web.
class _WebNotificationAdapter implements NotificationAdapter {
  @override
  Future<void> initialize() async {
    // No-op on web - notifications not supported
    if (kDebugMode) {
      debugPrint('[NotificationAdapter] Web platform - notifications disabled');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    // No permissions needed on web
    return false;
  }

  @override
  Future<void> showProgress({
    required int notificationId,
    required String title,
    required String text,
    required int progress,
    bool indeterminate = false,
  }) async {
    // No-op on web
    if (kDebugMode) {
      debugPrint('[NotificationAdapter] Web: Would show progress: $title ($progress%)');
    }
  }

  @override
  Future<void> updateProgress({
    required int notificationId,
    required int progress,
    String? text,
  }) async {
    // No-op on web
  }

  @override
  Future<void> showCompletion({
    required int notificationId,
    required String title,
    required String text,
    required bool success,
  }) async {
    // No-op on web
    if (kDebugMode) {
      debugPrint('[NotificationAdapter] Web: Would show completion: $title');
    }
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    // No-op on web
  }

  @override
  Future<void> cancelAllNotifications() async {
    // No-op on web
  }
}
