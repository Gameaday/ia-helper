import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permission helpers.
///
/// Storage model (issues #81 / #82, Nov 2026): every download, cache and
/// preview write goes to app-scoped directories (path_provider), which are
/// writable on every supported Android version (API 21+) with NO runtime
/// storage permission. The app therefore declares and requests no storage
/// permissions at all. This class is kept as a stable seam for callers;
/// the planned SAF download-location picker (#90) also needs no permission
/// (persistable URI grants).
///
/// Download notifications (#92) re-introduce exactly one runtime
/// permission: POST_NOTIFICATIONS (Android 13+), requested in-context at
/// the first download of a session - never at app launch.
class PermissionUtils {
  /// Tracks whether the POST_NOTIFICATIONS ask already happened this
  /// session (#92): the system dialog must never nag on every download.
  static bool _notificationAskAttempted = false;

  /// No-op: app-scoped storage requires no runtime grant on any supported
  /// Android version, so nothing is ever prompted. Always returns true.
  static Future<bool> requestStoragePermissions() async => true;

  /// No-op check: always true (see [requestStoragePermissions]).
  static Future<bool> hasStoragePermissions() async => true;

  /// Request POST_NOTIFICATIONS in context (Android 13+ runtime grant,
  /// #92). Shows the system dialog at most once per app session - the
  /// first download triggers it; later downloads just re-check the
  /// current state without prompting. On Android 12 and below the
  /// permission does not exist and the master notification toggle is the
  /// only gate; on web there are no native notifications at all.
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    if (_notificationAskAttempted) {
      return hasNotificationPermission();
    }
    _notificationAskAttempted = true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      // Plugin channel unavailable (test VM, unsupported platform):
      // treat as denied rather than crashing the download flow.
      return false;
    }
  }

  /// Whether notifications may be posted right now (no prompt).
  static Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      return (await Permission.notification.status).isGranted;
    } catch (_) {
      return false;
    }
  }
}
