/// Cache metrics for identifier verification
///
/// Tracks cache performance to measure API call savings and optimize
/// the two-level normalization strategy.
class IdentifierCacheMetrics {
  /// Total number of cache hits (found in cache)
  final int cacheHits;

  /// Total number of cache misses (not in cache, API call needed)
  final int cacheMisses;

  /// Number of times standard normalization succeeded
  final int standardHits;

  /// Number of times strict normalization succeeded (fallback)
  final int strictHits;

  /// Number of times alternative variants succeeded
  final int alternativeHits;

  /// Number of expired cache entries (evicted)
  final int cacheExpired;

  /// Total number of API calls made
  final int apiCallsMade;

  /// Total number of API calls saved by cache
  final int apiCallsSaved;

  /// Timestamp when metrics were last reset
  final DateTime lastReset;

  IdentifierCacheMetrics({
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.standardHits = 0,
    this.strictHits = 0,
    this.alternativeHits = 0,
    this.cacheExpired = 0,
    this.apiCallsMade = 0,
    this.apiCallsSaved = 0,
    DateTime? lastReset,
  }) : lastReset = lastReset ?? DateTime(2025, 1, 1);

  /// Cache hit rate (0.0 to 1.0)
  double get hitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  /// Cache hit rate as percentage string
  String get hitRatePercent {
    return '${(hitRate * 100).toStringAsFixed(1)}%';
  }

  /// API call reduction rate (0.0 to 1.0)
  double get apiReductionRate {
    final total = apiCallsMade + apiCallsSaved;
    return total > 0 ? apiCallsSaved / total : 0.0;
  }

  /// API call reduction as percentage string
  String get apiReductionPercent {
    return '${(apiReductionRate * 100).toStringAsFixed(1)}%';
  }

  /// Standard normalization success rate (0.0 to 1.0)
  double get standardSuccessRate {
    final totalHits = standardHits + strictHits + alternativeHits;
    return totalHits > 0 ? standardHits / totalHits : 0.0;
  }

  /// Strict normalization success rate (0.0 to 1.0)
  double get strictSuccessRate {
    final totalHits = standardHits + strictHits + alternativeHits;
    return totalHits > 0 ? strictHits / totalHits : 0.0;
  }

  /// Alternative variants success rate (0.0 to 1.0)
  double get alternativeSuccessRate {
    final totalHits = standardHits + strictHits + alternativeHits;
    return totalHits > 0 ? alternativeHits / totalHits : 0.0;
  }

  /// Total number of verifications attempted
  int get totalVerifications => cacheHits + cacheMisses;

  /// Total number of successful verifications
  int get totalSuccesses => standardHits + strictHits + alternativeHits;

  /// Average cache size (estimated from hits)
  int get estimatedCacheSize => cacheHits + cacheMisses - cacheExpired;

  /// Create a copy with updated values
  IdentifierCacheMetrics copyWith({
    int? cacheHits,
    int? cacheMisses,
    int? standardHits,
    int? strictHits,
    int? alternativeHits,
    int? cacheExpired,
    int? apiCallsMade,
    int? apiCallsSaved,
    DateTime? lastReset,
  }) {
    return IdentifierCacheMetrics(
      cacheHits: cacheHits ?? this.cacheHits,
      cacheMisses: cacheMisses ?? this.cacheMisses,
      standardHits: standardHits ?? this.standardHits,
      strictHits: strictHits ?? this.strictHits,
      alternativeHits: alternativeHits ?? this.alternativeHits,
      cacheExpired: cacheExpired ?? this.cacheExpired,
      apiCallsMade: apiCallsMade ?? this.apiCallsMade,
      apiCallsSaved: apiCallsSaved ?? this.apiCallsSaved,
      lastReset: lastReset ?? this.lastReset,
    );
  }

  /// Increment cache hits
  IdentifierCacheMetrics incrementHit({
    bool isStandard = false,
    bool isStrict = false,
    bool isAlternative = false,
  }) {
    return copyWith(
      cacheHits: cacheHits + 1,
      apiCallsSaved: apiCallsSaved + 1,
      standardHits: isStandard ? standardHits + 1 : standardHits,
      strictHits: isStrict ? strictHits + 1 : strictHits,
      alternativeHits: isAlternative ? alternativeHits + 1 : alternativeHits,
    );
  }

  /// Increment cache miss (API call needed)
  IdentifierCacheMetrics incrementMiss() {
    return copyWith(
      cacheMisses: cacheMisses + 1,
      apiCallsMade: apiCallsMade + 1,
    );
  }

  /// Increment expired entries
  IdentifierCacheMetrics incrementExpired() {
    return copyWith(cacheExpired: cacheExpired + 1);
  }

  /// Reset all metrics
  IdentifierCacheMetrics reset() {
    return IdentifierCacheMetrics(lastReset: DateTime.now());
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'standardHits': standardHits,
      'strictHits': strictHits,
      'alternativeHits': alternativeHits,
      'cacheExpired': cacheExpired,
      'apiCallsMade': apiCallsMade,
      'apiCallsSaved': apiCallsSaved,
      'lastReset': lastReset.toIso8601String(),
    };
  }

  /// Create from JSON
  factory IdentifierCacheMetrics.fromJson(Map<String, dynamic> json) {
    return IdentifierCacheMetrics(
      cacheHits: json['cacheHits'] as int? ?? 0,
      cacheMisses: json['cacheMisses'] as int? ?? 0,
      standardHits: json['standardHits'] as int? ?? 0,
      strictHits: json['strictHits'] as int? ?? 0,
      alternativeHits: json['alternativeHits'] as int? ?? 0,
      cacheExpired: json['cacheExpired'] as int? ?? 0,
      apiCallsMade: json['apiCallsMade'] as int? ?? 0,
      apiCallsSaved: json['apiCallsSaved'] as int? ?? 0,
      lastReset: json['lastReset'] != null
          ? DateTime.parse(json['lastReset'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'IdentifierCacheMetrics('
        'hitRate: $hitRatePercent, '
        'apiReduction: $apiReductionPercent, '
        'standardHits: $standardHits, '
        'strictHits: $strictHits, '
        'alternativeHits: $alternativeHits, '
        'totalVerifications: $totalVerifications'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return other is IdentifierCacheMetrics &&
        other.cacheHits == cacheHits &&
        other.cacheMisses == cacheMisses &&
        other.standardHits == standardHits &&
        other.strictHits == strictHits &&
        other.alternativeHits == alternativeHits &&
        other.cacheExpired == cacheExpired &&
        other.apiCallsMade == apiCallsMade &&
        other.apiCallsSaved == apiCallsSaved;
  }

  @override
  int get hashCode => Object.hash(
    cacheHits,
    cacheMisses,
    standardHits,
    strictHits,
    alternativeHits,
    cacheExpired,
    apiCallsMade,
    apiCallsSaved,
  );
}
