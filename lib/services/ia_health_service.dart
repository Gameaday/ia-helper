import 'package:http/http.dart' as http;
import '../core/constants/internet_archive_constants.dart';

/// Model for Internet Archive service health status
class IAHealthStatus {
  final bool isAvailable;
  final int? responseTimeMs;
  final String? version;
  final String? errorMessage;
  final DateTime timestamp;

  IAHealthStatus({
    required this.isAvailable,
    this.responseTimeMs,
    this.version,
    this.errorMessage,
    required this.timestamp,
  });

  bool get isHealthy =>
      isAvailable && responseTimeMs != null && responseTimeMs! < 5000;

  String get statusText {
    if (!isAvailable) return 'Unavailable';
    if (responseTimeMs == null) return 'Unknown';
    if (responseTimeMs! < 1000) return 'Excellent';
    if (responseTimeMs! < 3000) return 'Good';
    if (responseTimeMs! < 5000) return 'Fair';
    return 'Slow';
  }
}

/// Model for Internet Archive endpoint status
class IAEndpointStatus {
  final String name;
  final String endpoint;
  final bool isAvailable;
  final int? responseTimeMs;
  final String? errorMessage;

  IAEndpointStatus({
    required this.name,
    required this.endpoint,
    required this.isAvailable,
    this.responseTimeMs,
    this.errorMessage,
  });

  bool get isHealthy =>
      isAvailable && responseTimeMs != null && responseTimeMs! < 5000;
}

/// Service for checking Internet Archive health and status
class IAHealthService {
  /// Check main archive.org availability
  static Future<IAHealthStatus> checkMainSite() async {
    return _checkEndpoint('${IAEndpoints.base}/');
  }

  /// Check metadata API availability
  static Future<IAEndpointStatus> checkMetadataApi() async {
    const testIdentifier =
        'stats'; // archive.org/details/stats exists and is lightweight
    return _checkEndpointStatus(
      'Metadata API',
      '${IAEndpoints.metadata}/$testIdentifier',
    );
  }

  /// Check search API availability
  static Future<IAEndpointStatus> checkSearchApi() async {
    const testQuery = 'mediatype:texts&rows=1';
    return _checkEndpointStatus(
      'Search API',
      '${IAEndpoints.advancedSearch}?q=$testQuery&output=json',
    );
  }

  /// Check download service availability
  static Future<IAEndpointStatus> checkDownloadService() async {
    const testUrl = '${IAEndpoints.base}/';
    return _checkEndpointStatus('Download Service', testUrl);
  }

  /// Check all endpoints
  static Future<List<IAEndpointStatus>> checkAllEndpoints() async {
    final results = await Future.wait([
      checkMetadataApi(),
      checkSearchApi(),
      checkDownloadService(),
    ]);
    return results;
  }

  /// Internal method to check endpoint and return health status
  static Future<IAHealthStatus> _checkEndpoint(String url) async {
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'text/html,application/json'},
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();
      final responseTimeMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200 || response.statusCode == 302) {
        return IAHealthStatus(
          isAvailable: true,
          responseTimeMs: responseTimeMs,
          timestamp: timestamp,
        );
      } else {
        return IAHealthStatus(
          isAvailable: false,
          responseTimeMs: responseTimeMs,
          errorMessage: 'HTTP ${response.statusCode}',
          timestamp: timestamp,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return IAHealthStatus(
        isAvailable: false,
        errorMessage: e.toString(),
        timestamp: timestamp,
      );
    }
  }

  /// Internal method to check endpoint status
  static Future<IAEndpointStatus> _checkEndpointStatus(
    String name,
    String endpoint,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {'Accept': 'application/json,text/html'},
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();
      final responseTimeMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200 || response.statusCode == 302) {
        return IAEndpointStatus(
          name: name,
          endpoint: endpoint,
          isAvailable: true,
          responseTimeMs: responseTimeMs,
        );
      } else {
        return IAEndpointStatus(
          name: name,
          endpoint: endpoint,
          isAvailable: false,
          responseTimeMs: responseTimeMs,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      stopwatch.stop();
      return IAEndpointStatus(
        name: name,
        endpoint: endpoint,
        isAvailable: false,
        errorMessage: e.toString(),
      );
    }
  }
}
