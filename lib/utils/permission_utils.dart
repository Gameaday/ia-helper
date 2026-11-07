import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling runtime permissions
class PermissionUtils {
  /// Check and request storage permissions based on Android version
  static Future<bool> requestStoragePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // iOS handles permissions differently
    }

    try {
      // For Android 13+ (API 33+), app-scoped storage needs no runtime prompt (#81)
      // For Android 10-12 (API 29-32), we use scoped storage
      // For Android 9 and below (API 28-), we use legacy storage permissions

      if (await _isAndroid13OrHigher()) {
        // Android 13+ - App-scoped storage requires no runtime permission (#81)
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
        // Android 13+ - App-scoped storage; no permission required (#81)
        return true;
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

  /// Platform channel to the native side (MainActivity.kt).
  static const MethodChannel _platformChannel = MethodChannel(
      'com.gameaday.internet_archive_helper/platform');

  /// Cached Build.VERSION.SDK_INT from the platform channel.
  static int? _cachedSdkInt;

  /// Returns the device's real Android SDK_INT via the existing platform
  /// channel (getSdkInt). Falls back to 33 (modern path) only if the channel
  /// is somehow unavailable - the channel ships with the app, so this merely
  /// guards against non-standard embedders. Fix for #77: the old
  /// permission-availability heuristic never returned false, making the
  /// legacy storage paths unreachable on Android 10-12.
  static Future<int> _androidSdkInt() async {
    final cached = _cachedSdkInt;
    if (cached != null) return cached;
    int sdk;
    try {
      sdk = await _platformChannel.invokeMethod<int>('getSdkInt') ?? 33;
    } on PlatformException catch (e) {
      debugPrint('SDK_INT channel error ($e); assuming API 33+');
      sdk = 33;
    } on MissingPluginException {
      debugPrint('SDK_INT channel not registered; assuming API 33+');
      sdk = 33;
    }
    _cachedSdkInt = sdk;
    return sdk;
  }

  /// Check if running on Android 13 or higher (API 33+)
  static Future<bool> _isAndroid13OrHigher() async {
    return await _androidSdkInt() >= 33;
  }

  /// Check if running on Android 10 or higher (API 29+)
  static Future<bool> _isAndroid10OrHigher() async {
    return await _androidSdkInt() >= 29;
  }
}
