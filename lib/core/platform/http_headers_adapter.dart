import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Platform adapter for HTTP headers
///
/// Provides platform-appropriate HTTP headers:
/// - Native: Custom User-Agent with app info
/// - Web: Browser handles User-Agent automatically (can't be set)
///
/// This eliminates platform checks from HTTP client code.
class HttpHeadersAdapter {
  static final HttpHeadersAdapter _instance = HttpHeadersAdapter._internal();
  factory HttpHeadersAdapter() => _instance;
  HttpHeadersAdapter._internal();

  // Flutter version constant (since Flutter doesn't expose this at runtime)
  static const String _kFlutterVersion = '3.35.5';

  /// Get platform-appropriate HTTP headers
  ///
  /// Returns headers that are safe to use on the current platform.
  /// On web, omits User-Agent since browsers set it automatically.
  Map<String, String> getPlatformHeaders() {
    if (kIsWeb) {
      // Web: Browser sets User-Agent automatically
      // Setting it manually causes errors
      return const {};
    }

    // Native: Include custom User-Agent
    return {
      'User-Agent': _buildUserAgent(),
    };
  }

  /// Build User-Agent string for native platforms
  ///
  /// Format: "IA-Helper/1.0 (Android 13; API 33) Flutter/3.35.5 Dart/3.9.2"
  ///
  /// Components:
  /// - App name and version
  /// - Platform and OS version
  /// - Flutter version
  /// - Dart version
  String _buildUserAgent() {
    final appName = 'IA-Helper';
    // Using hardcoded version for now - matches pubspec.yaml version: 1.0.0+1
    // Can be upgraded to package_info_plus later if dynamic version is needed
    final appVersion = '1.0.0';

    final platformInfo = _getPlatformInfo();
    final flutterVersion = _getFlutterVersion();

    return '$appName/$appVersion $platformInfo $flutterVersion';
  }

  /// Get platform information string
  ///
  /// Examples:
  /// - Android: "(Android 13; API 33)"
  /// - iOS: "(iOS 17.0; iPhone14,2)"
  /// - Linux: "(Linux x86_64)"
  String _getPlatformInfo() {
    if (kIsWeb) {
      return '(Web)';
    }

    try {
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;

      if (Platform.isAndroid) {
        return '(Android; $osVersion)';
      } else if (Platform.isIOS) {
        return '(iOS; $osVersion)';
      } else if (Platform.isLinux) {
        return '(Linux)';
      } else if (Platform.isMacOS) {
        return '(macOS)';
      } else if (Platform.isWindows) {
        return '(Windows)';
      }

      return '($os)';
    } catch (e) {
      return '(Unknown)';
    }
  }

  /// Get Flutter/Dart version string
  ///
  /// Format: "Flutter/3.35.5 Dart/3.9.2"
  ///
  /// Note: Flutter version is hardcoded since Flutter doesn't expose
  /// it at runtime. Dart version comes from Platform.version.
  String _getFlutterVersion() {
    if (kIsWeb) {
      return 'Flutter/$_kFlutterVersion (Web)';
    }

    try {
      // Extract Dart version from Platform.version
      // Format: "3.9.2 (stable) ..." -> extract "3.9.2"
      final platformVersion = Platform.version;
      final dartVersion = platformVersion.split(' ').first;

      return 'Flutter/$_kFlutterVersion Dart/$dartVersion';
    } catch (e) {
      return 'Flutter/$_kFlutterVersion';
    }
  }

  /// Merge user headers with platform headers
  ///
  /// Platform headers are added first, then user headers.
  /// User headers can override platform headers if needed.
  Map<String, String> mergeHeaders(Map<String, String>? userHeaders) {
    final headers = <String, String>{};

    // Add platform headers first
    headers.addAll(getPlatformHeaders());

    // Add user headers (can override platform headers)
    if (userHeaders != null) {
      headers.addAll(userHeaders);
    }

    return headers;
  }

  /// Get a complete User-Agent string (for logging/debugging)
  ///
  /// Returns the User-Agent that would be sent on native platforms,
  /// or a description for web.
  String getUserAgent() {
    if (kIsWeb) {
      return 'Browser User-Agent (auto-detected)';
    }
    return _buildUserAgent();
  }

  /// Check if platform supports custom User-Agent
  bool get supportsCustomUserAgent => !kIsWeb;

  /// Get platform name for display
  String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  /// Debug: Print current platform headers
  void debugPrintHeaders() {
    if (!kDebugMode) return;

    debugPrint('[HttpHeadersAdapter] Platform: $platformName');
    debugPrint('[HttpHeadersAdapter] User-Agent: ${getUserAgent()}');
    debugPrint('[HttpHeadersAdapter] Headers: ${getPlatformHeaders()}');
  }
}
