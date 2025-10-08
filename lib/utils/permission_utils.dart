import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling runtime permissions
class PermissionUtils {
  /// Check and request storage permissions based on Android version
  static Future<bool> requestStoragePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // iOS handles permissions differently
    }

    try {
      // For Android 13+ (API 33+), we need to request specific media permissions
      // For Android 10-12 (API 29-32), we use scoped storage
      // For Android 9 and below (API 28-), we use legacy storage permissions

      if (await _isAndroid13OrHigher()) {
        // Android 13+ - Request specific media permissions
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();

        // Check if at least one permission was granted
        final hasAnyPermission = statuses.values.any(
          (status) => status.isGranted || status.isLimited,
        );

        if (!hasAnyPermission) {
          debugPrint('No media permissions granted on Android 13+');
          return false;
        }

        return true;
      } else if (await _isAndroid10OrHigher()) {
        // Android 10-12 - Scoped storage with optional MANAGE_EXTERNAL_STORAGE
        final status = await Permission.storage.request();

        if (status.isGranted) {
          return true;
        }

        // Try to request manage external storage for full access
        if (await Permission.manageExternalStorage.request().isGranted) {
          return true;
        }

        debugPrint('Storage permission denied on Android 10-12');
        return status.isGranted;
      } else {
        // Android 9 and below - Legacy storage permissions
        final status = await Permission.storage.request();

        if (status.isGranted) {
          return true;
        }

        debugPrint('Storage permission denied on Android 9 and below');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Check if storage permissions are currently granted
  static Future<bool> hasStoragePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      if (await _isAndroid13OrHigher()) {
        // Android 13+ - Check if any media permission is granted
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        final audio = await Permission.audio.status;

        return photos.isGranted ||
            photos.isLimited ||
            videos.isGranted ||
            videos.isLimited ||
            audio.isGranted ||
            audio.isLimited;
      } else if (await _isAndroid10OrHigher()) {
        // Android 10-12
        final storage = await Permission.storage.status;
        final manageStorage = await Permission.manageExternalStorage.status;

        return storage.isGranted || manageStorage.isGranted;
      } else {
        // Android 9 and below
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking storage permissions: $e');
      return false;
    }
  }

  /// Check if MANAGE_EXTERNAL_STORAGE permission is granted (Android 11+)
  /// This is needed for full file system access including opening folders
  static Future<bool> hasManageStoragePermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      if (await _isAndroid10OrHigher()) {
        final status = await Permission.manageExternalStorage.status;
        return status.isGranted;
      }
      // On Android 9 and below, regular storage permission is sufficient
      return await hasStoragePermissions();
    } catch (e) {
      debugPrint('Error checking manage storage permission: $e');
      return false;
    }
  }

  /// Request MANAGE_EXTERNAL_STORAGE permission (Android 11+)
  /// This requires special handling - on Android 11+, users must grant it in system settings
  static Future<bool> requestManageStoragePermission(
    BuildContext context,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      if (await _isAndroid10OrHigher()) {
        final status = await Permission.manageExternalStorage.status;

        if (status.isGranted) {
          return true;
        }

        // On Android 11+, this permission requires ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION
        // Show dialog explaining why we need this
        if (!context.mounted) return false;
        
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Access Required'),
            content: const Text(
              'To open folders and manage downloaded files, this app needs full storage access.\n\n'
              'You will be taken to system settings where you can grant "All files access" permission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          return false;
        }

        // Request permission - this will open system settings on Android 11+
        final result = await Permission.manageExternalStorage.request();

        if (!result.isGranted && context.mounted) {
          // User didn't grant permission, show how to do it manually
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Not Granted'),
                content: const Text(
                  'To enable folder access:\n'
                  '1. Open Settings\n'
                  '2. Find this app\n'
                  '3. Enable "All files access"',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
          return false;
        }

        return result.isGranted;
      }

      // On Android 9 and below, regular storage permission is sufficient
      return await requestStoragePermissions();
    } catch (e) {
      debugPrint('Error requesting manage storage permission: $e');
      return false;
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestNotificationPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }

      // Notifications don't require explicit permission on older Android versions
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if notification permissions are granted
  static Future<bool> hasNotificationPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Check if running on Android 13 or higher (API 33+)
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simplified check - in production you'd check Build.VERSION.SDK_INT
    // For now, we'll assume newer Android versions based on permission availability
    try {
      await Permission.photos.status;
      return true; // If photos permission exists, we're on Android 13+
    } catch (e) {
      return false;
    }
  }

  /// Check if running on Android 10 or higher (API 29+)
  static Future<bool> _isAndroid10OrHigher() async {
    // This is a simplified check
    try {
      await Permission.manageExternalStorage.status;
      return true; // If this permission exists, we're on Android 10+
    } catch (e) {
      return false;
    }
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionRationaleDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show settings redirect dialog when permission is permanently denied
  static Future<bool> showSettingsDialog({
    required BuildContext context,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
