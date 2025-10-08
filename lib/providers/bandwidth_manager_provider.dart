import 'package:flutter/foundation.dart';
import '../services/bandwidth_throttle.dart';
import '../models/bandwidth_preset.dart';

/// Provider for managing bandwidth throttling across the application
///
/// This provider wraps BandwidthManager and BandwidthThrottle from Day 3,
/// providing a Flutter-friendly state management layer with presets and
/// real-time usage statistics.
class BandwidthManagerProvider extends ChangeNotifier {
  BandwidthManager? _manager;
  BandwidthPreset _currentPreset = BandwidthPreset.unlimited;
  DateTime _sessionStart = DateTime.now();
  int _totalBytesTransferred = 0;
  final Map<String, BandwidthThrottle> _activeThrottles = {};

  /// Get current bandwidth preset
  BandwidthPreset get currentPreset => _currentPreset;

  /// Get current bandwidth limit in bytes per second (0 = unlimited)
  int get currentLimit => _currentPreset.bytesPerSecond;

  /// Check if bandwidth limiting is enabled
  bool get isLimitEnabled => !_currentPreset.isUnlimited;

  /// Get number of active downloads with throttling
  int get activeThrottleCount => _activeThrottles.length;

  /// Get current bandwidth usage statistics
  BandwidthUsage get usage {
    if (_manager == null || _currentPreset.isUnlimited) {
      return BandwidthUsage.empty;
    }

    // Calculate current usage from active throttles
    double currentUsage = 0.0;
    for (final throttle in _activeThrottles.values) {
      // Estimate current usage based on recent activity
      // This is approximate since BandwidthThrottle doesn't expose current rate
      currentUsage += _estimateThrottleRate(throttle);
    }

    final perDownloadRate = _activeThrottles.isEmpty
        ? 0.0
        : _currentPreset.bytesPerSecond / _activeThrottles.length;

    return BandwidthUsage(
      currentBytesPerSecond: currentUsage,
      maxBytesPerSecond: _currentPreset.bytesPerSecond,
      activeDownloads: _activeThrottles.length,
      perDownloadBytesPerSecond: perDownloadRate,
      isThrottled: currentUsage > _currentPreset.bytesPerSecond * 0.8,
      totalBytesTransferred: _totalBytesTransferred,
      sessionDuration: DateTime.now().difference(_sessionStart),
    );
  }

  /// Initialize bandwidth manager with a preset
  void initialize(BandwidthPreset preset) {
    _currentPreset = preset;
    _sessionStart = DateTime.now();
    _totalBytesTransferred = 0;

    if (!preset.isUnlimited) {
      _manager = BandwidthManager(totalBytesPerSecond: preset.bytesPerSecond);
      if (kDebugMode) {
        print('[BandwidthManagerProvider] Initialized with ${preset.displayName}');
      }
    } else {
      _manager = null;
      if (kDebugMode) {
        print('[BandwidthManagerProvider] Unlimited bandwidth mode');
      }
    }

    notifyListeners();
  }

  /// Change bandwidth preset
  void changePreset(BandwidthPreset newPreset) {
    if (newPreset == _currentPreset) return;

    if (kDebugMode) {
      print('[BandwidthManagerProvider] Changing preset: '
          '${_currentPreset.displayName} → ${newPreset.displayName}');
    }

    // Clean up old manager
    _manager = null;

    // Initialize with new preset
    initialize(newPreset);
  }

  /// Create a throttle for a download
  ///
  /// Returns null if bandwidth limiting is disabled (unlimited mode)
  BandwidthThrottle? createThrottle(String downloadId) {
    if (_manager == null) {
      if (kDebugMode) {
        print('[BandwidthManagerProvider] Unlimited mode - no throttle for $downloadId');
      }
      return null;
    }

    final throttle = _manager!.createThrottle(downloadId);
    _activeThrottles[downloadId] = throttle;

    if (kDebugMode) {
      print('[BandwidthManagerProvider] Created throttle for $downloadId '
          '(${_activeThrottles.length} active)');
    }

    notifyListeners();
    return throttle;
  }

  /// Remove a throttle when download completes/fails
  void removeThrottle(String downloadId) {
    if (_activeThrottles.remove(downloadId) != null) {
      _manager?.removeThrottle(downloadId);

      if (kDebugMode) {
        print('[BandwidthManagerProvider] Removed throttle for $downloadId '
            '(${_activeThrottles.length} remaining)');
      }

      notifyListeners();
    }
  }

  /// Record bytes transferred (for statistics)
  void recordBytesTransferred(int bytes) {
    _totalBytesTransferred += bytes;
    // Don't notify listeners on every byte - too frequent
    // Statistics will be calculated on demand via `usage` getter
  }

  /// Pause all active throttles
  void pauseAll() {
    if (_manager == null) return;

    for (final throttle in _activeThrottles.values) {
      throttle.pause();
    }

    if (kDebugMode) {
      print('[BandwidthManagerProvider] Paused all throttles');
    }

    notifyListeners();
  }

  /// Resume all active throttles
  void resumeAll() {
    if (_manager == null) return;

    for (final throttle in _activeThrottles.values) {
      throttle.resume();
    }

    if (kDebugMode) {
      print('[BandwidthManagerProvider] Resumed all throttles');
    }

    notifyListeners();
  }

  /// Reset session statistics
  void resetStatistics() {
    _sessionStart = DateTime.now();
    _totalBytesTransferred = 0;

    if (kDebugMode) {
      print('[BandwidthManagerProvider] Reset statistics');
    }

    notifyListeners();
  }

  /// Estimate current rate for a throttle (approximate)
  double _estimateThrottleRate(BandwidthThrottle throttle) {
    // Since BandwidthThrottle doesn't expose current rate,
    // estimate based on allocated bandwidth
    if (_manager == null || _activeThrottles.isEmpty) return 0.0;

    // Equal distribution among active downloads
    return _currentPreset.bytesPerSecond / _activeThrottles.length;
  }

  @override
  void dispose() {
    _manager = null;
    _activeThrottles.clear();
    super.dispose();
  }
}
