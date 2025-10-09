import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/internet_archive_constants.dart';

/// Service for managing Internet Archive API settings
///
/// Provides persistent storage and retrieval of API-related settings
/// that demonstrate good API citizenship and allow user customization.
class ApiSettingsService {
  static const String _keyReducedPriority = 'ia_api_reduced_priority';
  static const String _keyAutoReduceLarge = 'ia_api_auto_reduce_large';
  static const String _keyLargeSizeThresholdMB = 'ia_api_large_threshold_mb';
  static const String _keyRequestDelayMs = 'ia_api_request_delay_ms';
  static const String _keyMaxRequestsPerMinute = 'ia_api_max_requests_per_min';
  static const String _keySendDoNotTrack = 'ia_api_send_dnt';
  static const String _keyRespectRetryAfter = 'ia_api_respect_retry_after';
  static const String _keyCustomUserAgent = 'ia_api_custom_user_agent';

  /// Get custom User-Agent string (null means use default)
  static Future<String?> getCustomUserAgent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomUserAgent);
  }

  /// Set custom User-Agent string (null to use default)
  static Future<void> setCustomUserAgent(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_keyCustomUserAgent);
    } else {
      await prefs.setString(_keyCustomUserAgent, value);
    }
  }

  /// Get whether to use reduced priority by default
  static Future<bool> getReducedPriority() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReducedPriority) ??
        IADownloadPriority.defaultReducedPriority;
  }

  /// Set whether to use reduced priority by default
  static Future<void> setReducedPriority(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedPriority, value);
  }

  /// Get whether to auto-enable reduced priority for large files
  static Future<bool> getAutoReduceLargeFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoReduceLarge) ??
        IADownloadPriority.autoReduceLargeFiles;
  }

  /// Set whether to auto-enable reduced priority for large files
  static Future<void> setAutoReduceLargeFiles(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoReduceLarge, value);
  }

  /// Get large file size threshold in MB
  static Future<int> getLargeSizeThresholdMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLargeSizeThresholdMB) ??
        (IADownloadPriority.largeSizeThresholdBytes / (1024 * 1024)).round();
  }

  /// Set large file size threshold in MB
  static Future<void> setLargeSizeThresholdMB(int mb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLargeSizeThresholdMB, mb);
  }

  /// Get minimum request delay in milliseconds
  static Future<int> getRequestDelayMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRequestDelayMs) ?? IARateLimits.minRequestDelayMs;
  }

  /// Set minimum request delay in milliseconds
  static Future<void> setRequestDelayMs(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRequestDelayMs, ms);
  }

  /// Get maximum requests per minute
  static Future<int> getMaxRequestsPerMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxRequestsPerMinute) ??
        IARateLimits.maxRequestsPerMinute;
  }

  /// Set maximum requests per minute
  static Future<void> setMaxRequestsPerMinute(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxRequestsPerMinute, count);
  }

  /// Get whether to send Do Not Track header
  static Future<bool> getSendDoNotTrack() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySendDoNotTrack) ?? true;
  }

  /// Set whether to send Do Not Track header
  static Future<void> setSendDoNotTrack(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySendDoNotTrack, value);
  }

  /// Get whether to respect Retry-After headers
  static Future<bool> getRespectRetryAfter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRespectRetryAfter) ?? true;
  }

  /// Set whether to respect Retry-After headers
  static Future<void> setRespectRetryAfter(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRespectRetryAfter, value);
  }

  /// Reset all settings to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyReducedPriority),
      prefs.remove(_keyAutoReduceLarge),
      prefs.remove(_keyLargeSizeThresholdMB),
      prefs.remove(_keyRequestDelayMs),
      prefs.remove(_keyMaxRequestsPerMinute),
      prefs.remove(_keySendDoNotTrack),
      prefs.remove(_keyRespectRetryAfter),
      prefs.remove(_keyCustomUserAgent),
    ]);
  }
}
