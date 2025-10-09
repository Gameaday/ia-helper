/// API intensity level for controlling data usage and API call frequency
enum ApiIntensityLevel {
  /// Maximum detail with all features enabled (~350 KB per item)
  /// Best for WiFi connections and unlimited data plans
  full,

  /// Balanced performance and detail (~75 KB per item)
  /// Recommended for most users, works well on mobile data
  standard,

  /// Fast and lightweight (~7 KB per item)
  /// Best for slow connections or limited data plans
  minimal,

  /// Offline mode, no network access (0 KB)
  /// Only uses cached data
  cacheOnly,
}

/// Settings for controlling API call intensity and data usage
///
/// This class provides granular control over how much data the app fetches
/// from the Internet Archive API. Users can choose between preset levels
/// or customize individual settings.
///
/// Example usage:
/// ```dart
/// // Use a preset
/// final settings = ApiIntensitySettings.standard();
///
/// // Customize
/// final custom = ApiIntensitySettings(
///   level: ApiIntensityLevel.standard,
///   loadThumbnails: false,
/// );
/// ```
class ApiIntensitySettings {
  /// The base intensity level
  final ApiIntensityLevel level;

  /// Whether to load thumbnail images for search results
  final bool loadThumbnails;

  /// Whether to preload metadata for popular/trending items
  final bool preloadMetadata;

  /// Whether to load extended metadata (full descriptions, subjects, etc.)
  final bool loadExtendedMetadata;

  /// Whether to load statistics (downloads, views, ratings)
  final bool loadStatistics;

  /// Whether to load related/similar items
  final bool loadRelatedItems;

  /// Maximum number of concurrent API requests
  final int maxConcurrentRequests;

  /// Create settings with custom values
  ///
  /// All fields must be explicitly provided when using this constructor.
  const ApiIntensitySettings({
    required this.level,
    required this.loadThumbnails,
    required this.preloadMetadata,
    required this.loadExtendedMetadata,
    required this.loadStatistics,
    required this.loadRelatedItems,
    required this.maxConcurrentRequests,
  });

  /// Full intensity preset: all features enabled
  factory ApiIntensitySettings.full() => const ApiIntensitySettings(
    level: ApiIntensityLevel.full,
    loadThumbnails: true,
    preloadMetadata: true,
    loadExtendedMetadata: true,
    loadStatistics: true,
    loadRelatedItems: true,
    maxConcurrentRequests: 10,
  );

  /// Standard intensity preset: balanced (recommended)
  factory ApiIntensitySettings.standard() => const ApiIntensitySettings(
    level: ApiIntensityLevel.standard,
    loadThumbnails: true,
    preloadMetadata: true,
    loadExtendedMetadata: false,
    loadStatistics: true,
    loadRelatedItems: false,
    maxConcurrentRequests: 5,
  );

  /// Minimal intensity preset: fast and lightweight
  factory ApiIntensitySettings.minimal() => const ApiIntensitySettings(
    level: ApiIntensityLevel.minimal,
    loadThumbnails: false,
    preloadMetadata: false,
    loadExtendedMetadata: false,
    loadStatistics: false,
    loadRelatedItems: false,
    maxConcurrentRequests: 2,
  );

  /// Cache-only preset: offline mode
  factory ApiIntensitySettings.cacheOnly() => const ApiIntensitySettings(
    level: ApiIntensityLevel.cacheOnly,
    loadThumbnails: false,
    preloadMetadata: false,
    loadExtendedMetadata: false,
    loadStatistics: false,
    loadRelatedItems: false,
    maxConcurrentRequests: 0,
  );

  /// Estimated data usage per item in KB
  int get estimatedDataUsagePerItem {
    switch (level) {
      case ApiIntensityLevel.full:
        return 350;
      case ApiIntensityLevel.standard:
        return 75;
      case ApiIntensityLevel.minimal:
        return 7;
      case ApiIntensityLevel.cacheOnly:
        return 0;
    }
  }

  /// User-friendly description of this intensity level
  String get description {
    switch (level) {
      case ApiIntensityLevel.full:
        return 'Maximum detail with all features enabled. Best for WiFi.';
      case ApiIntensityLevel.standard:
        return 'Balanced performance and detail. Recommended for most users.';
      case ApiIntensityLevel.minimal:
        return 'Fast and lightweight. Best for slow connections.';
      case ApiIntensityLevel.cacheOnly:
        return 'Offline mode. No API calls, cached data only.';
    }
  }

  /// Short name for display in UI
  String get displayName {
    switch (level) {
      case ApiIntensityLevel.full:
        return '⚡⚡⚡ Full';
      case ApiIntensityLevel.standard:
        return '⚡⚡ Standard';
      case ApiIntensityLevel.minimal:
        return '⚡ Minimal';
      case ApiIntensityLevel.cacheOnly:
        return '📴 Cache Only';
    }
  }

  /// Estimated data usage for a given number of items
  String estimateDataUsage(int itemCount) {
    final totalKB = estimatedDataUsagePerItem * itemCount;
    if (totalKB >= 1024) {
      return '${(totalKB / 1024).toStringAsFixed(1)} MB';
    }
    return '$totalKB KB';
  }

  /// Whether network access is allowed
  bool get allowsNetworkAccess => level != ApiIntensityLevel.cacheOnly;

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'level': level.name,
    'loadThumbnails': loadThumbnails,
    'preloadMetadata': preloadMetadata,
    'loadExtendedMetadata': loadExtendedMetadata,
    'loadStatistics': loadStatistics,
    'loadRelatedItems': loadRelatedItems,
    'maxConcurrentRequests': maxConcurrentRequests,
  };

  /// Create from JSON
  factory ApiIntensitySettings.fromJson(Map<String, dynamic> json) {
    final level = ApiIntensityLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => ApiIntensityLevel.standard,
    );

    // If individual settings aren't in JSON, use the preset for that level
    final preset = ApiIntensitySettings.fromLevel(level);

    return ApiIntensitySettings(
      level: level,
      loadThumbnails: json['loadThumbnails'] as bool? ?? preset.loadThumbnails,
      preloadMetadata:
          json['preloadMetadata'] as bool? ?? preset.preloadMetadata,
      loadExtendedMetadata:
          json['loadExtendedMetadata'] as bool? ?? preset.loadExtendedMetadata,
      loadStatistics: json['loadStatistics'] as bool? ?? preset.loadStatistics,
      loadRelatedItems:
          json['loadRelatedItems'] as bool? ?? preset.loadRelatedItems,
      maxConcurrentRequests:
          json['maxConcurrentRequests'] as int? ?? preset.maxConcurrentRequests,
    );
  }

  /// Create a copy with modified fields
  ApiIntensitySettings copyWith({
    ApiIntensityLevel? level,
    bool? loadThumbnails,
    bool? preloadMetadata,
    bool? loadExtendedMetadata,
    bool? loadStatistics,
    bool? loadRelatedItems,
    int? maxConcurrentRequests,
  }) {
    return ApiIntensitySettings(
      level: level ?? this.level,
      loadThumbnails: loadThumbnails ?? this.loadThumbnails,
      preloadMetadata: preloadMetadata ?? this.preloadMetadata,
      loadExtendedMetadata: loadExtendedMetadata ?? this.loadExtendedMetadata,
      loadStatistics: loadStatistics ?? this.loadStatistics,
      loadRelatedItems: loadRelatedItems ?? this.loadRelatedItems,
      maxConcurrentRequests:
          maxConcurrentRequests ?? this.maxConcurrentRequests,
    );
  }

  /// Create from a preset level with default values
  factory ApiIntensitySettings.fromLevel(ApiIntensityLevel level) {
    switch (level) {
      case ApiIntensityLevel.full:
        return ApiIntensitySettings.full();
      case ApiIntensityLevel.standard:
        return ApiIntensitySettings.standard();
      case ApiIntensityLevel.minimal:
        return ApiIntensitySettings.minimal();
      case ApiIntensityLevel.cacheOnly:
        return ApiIntensitySettings.cacheOnly();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiIntensitySettings &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          loadThumbnails == other.loadThumbnails &&
          preloadMetadata == other.preloadMetadata &&
          loadExtendedMetadata == other.loadExtendedMetadata &&
          loadStatistics == other.loadStatistics &&
          loadRelatedItems == other.loadRelatedItems &&
          maxConcurrentRequests == other.maxConcurrentRequests;

  @override
  int get hashCode =>
      level.hashCode ^
      loadThumbnails.hashCode ^
      preloadMetadata.hashCode ^
      loadExtendedMetadata.hashCode ^
      loadStatistics.hashCode ^
      loadRelatedItems.hashCode ^
      maxConcurrentRequests.hashCode;

  @override
  String toString() =>
      'ApiIntensitySettings('
      'level: $level, '
      'loadThumbnails: $loadThumbnails, '
      'preloadMetadata: $preloadMetadata, '
      'loadExtendedMetadata: $loadExtendedMetadata, '
      'loadStatistics: $loadStatistics, '
      'loadRelatedItems: $loadRelatedItems, '
      'maxConcurrentRequests: $maxConcurrentRequests)';
}
