import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'rate_limiter.dart';
import '../models/rate_limit_status.dart';

/// Current Flutter SDK version for User-Agent header.
///
/// NOTE: Flutter doesn't expose SDK version at runtime without external dependencies.
/// This constant should be updated when upgrading Flutter SDK.
/// Run `flutter --version` to get the current version.
const String _kFlutterVersion = '3.35.5';

/// Metrics for tracking HTTP client operations
class HttpClientMetrics {
  int requests = 0;
  int retries = 0;
  int failures = 0;
  int timeouts = 0;
  int rateLimitHits = 0;
  int networkErrors = 0;
  int cacheHits = 0;
  int serverErrors = 0;

  @override
  String toString() {
    return 'HttpClientMetrics('
        'requests: $requests, '
        'retries: $retries, '
        'failures: $failures, '
        'timeouts: $timeouts, '
        'rateLimitHits: $rateLimitHits, '
        'networkErrors: $networkErrors, '
        'cacheHits: $cacheHits, '
        'serverErrors: $serverErrors'
        ')';
  }
}

/// Enhanced HTTP client for Archive.org API compliance.
///
/// Implements all Archive.org best practices:
/// 1. User-Agent header with app version and contact
/// 2. Exponential backoff retry (1s→2s→4s→8s→60s max)
/// 3. Respect Retry-After header from 429/503 responses
/// 4. Automatic rate limiting integration
/// 5. Request timeout handling
/// 6. Cancellation support
/// 7. ETag support for conditional GET requests (If-None-Match/304)
///
/// Usage:
/// ```dart
/// final client = IAHttpClient();
/// try {
///   // Simple GET request
///   final response = await client.get(Uri.parse('https://archive.org/...'));
///
///   // Conditional GET with ETag (returns 304 if not modified)
///   final etag = IAHttpClient.extractETag(response);
///   final response2 = await client.get(
///     Uri.parse('https://archive.org/...'),
///     ifNoneMatch: etag,
///   );
///   if (response2.statusCode == 304) {
///     // Cache is still valid, no need to re-download
///   }
/// } on IAHttpException catch (e) {
///   // Handle error
/// } finally {
///   client.close();
/// }
/// ```
class IAHttpClient {
  final http.Client _innerClient;
  final RateLimiter _rateLimiter;

  // Metrics tracking
  final HttpClientMetrics metrics = HttpClientMetrics();
  final String userAgent;
  final Duration defaultTimeout;
  final int maxRetries;
  final List<Duration> retryDelays;

  /// Track the last retry-after delay from server responses
  int? _lastRetryAfterSeconds;
  DateTime? _lastRetryAfterExpiry;

  /// Creates an HTTP client configured for Archive.org API.
  ///
  /// [userAgent]: Custom User-Agent string (required by Archive.org)
  /// [contact]: Contact email for User-Agent
  /// [innerClient]: Underlying HTTP client (for testing)
  /// [rateLimiter]: Rate limiter instance (uses global by default)
  /// [defaultTimeout]: Default request timeout (30s)
  /// [maxRetries]: Maximum retry attempts for transient errors (5)
  /// [customRetryDelays]: Custom exponential backoff delays
  IAHttpClient({
    String? userAgent,
    String contact = 'support@internetarchivehelper.app',
    http.Client? innerClient,
    RateLimiter? rateLimiter,
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetries = 5,
    List<Duration>? customRetryDelays,
  }) : _innerClient = innerClient ?? http.Client(),
       _rateLimiter = rateLimiter ?? archiveRateLimiter,
       userAgent =
           userAgent ??
           'InternetArchiveHelper/1.6.0 ($contact) Flutter/${_getFlutterVersion()}',
       retryDelays =
           customRetryDelays ??
           [
             const Duration(seconds: 1),
             const Duration(seconds: 2),
             const Duration(seconds: 4),
             const Duration(seconds: 8),
             const Duration(seconds: 60),
           ];

  /// GET request with automatic retry and rate limiting.
  ///
  /// [ifNoneMatch]: Optional ETag for conditional GET (304 Not Modified support)
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    String? ifNoneMatch,
  }) async {
    metrics.requests++;
    if (kDebugMode) {
      debugPrint('[IAHttpClient] GET ${url.host}${url.path}');
    }

    final response = await _executeWithRetry(
      () => _innerClient.get(
        url,
        headers: _mergeHeaders(headers, ifNoneMatch: ifNoneMatch),
      ),
      timeout: timeout,
    );

    // Track cache hits (304 Not Modified)
    if (response.statusCode == 304) {
      metrics.cacheHits++;
      if (kDebugMode) {
        debugPrint('[IAHttpClient] Cache hit (304) for ${url.path}');
      }
    }

    return response;
  }

  /// POST request with automatic retry and rate limiting.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    metrics.requests++;
    if (kDebugMode) {
      debugPrint('[IAHttpClient] POST ${url.host}${url.path}');
    }
    return _executeWithRetry(
      () => _innerClient.post(url, headers: _mergeHeaders(headers), body: body),
      timeout: timeout,
    );
  }

  /// HEAD request (useful for checking file existence/size).
  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    metrics.requests++;
    if (kDebugMode) {
      debugPrint('[IAHttpClient] HEAD ${url.host}${url.path}');
    }

    return _executeWithRetry(
      () => _innerClient.head(url, headers: _mergeHeaders(headers)),
      timeout: timeout,
    );
  }

  /// Download with streaming support (for large files).
  ///
  /// Returns a [http.StreamedResponse] for progressive reading.
  Future<http.StreamedResponse> getStream(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    metrics.requests++;
    if (kDebugMode) {
      debugPrint('[IAHttpClient] GET (stream) ${url.host}${url.path}');
    }

    return _executeWithRetry(() async {
      final request = http.Request('GET', url);
      request.headers.addAll(_mergeHeaders(headers));
      return await _innerClient.send(request);
    }, timeout: timeout);
  }

  /// Execute request with exponential backoff retry logic.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() request, {
    Duration? timeout,
    int attemptNumber = 0,
  }) async {
    // Apply rate limiting
    await _rateLimiter.acquire();

    try {
      // Execute request with timeout
      final response = await request().timeout(
        timeout ?? defaultTimeout,
        onTimeout: () {
          throw IAHttpException(
            'Request timed out after ${(timeout ?? defaultTimeout).inSeconds}s',
            type: IAHttpExceptionType.timeout,
          );
        },
      );

      // Always parse retry-after header for tracking (even if not retrying)
      final statusCode = _getStatusCode(response);
      if (statusCode == 429 || statusCode == 503) {
        _parseRetryAfter(response);
      }

      // Track rate limit hits
      if (statusCode == 429) {
        metrics.rateLimitHits++;
      }

      // Track server errors
      if (statusCode >= 500) {
        metrics.serverErrors++;
      }

      // Check if retry is needed based on status code
      if (_shouldRetry(response, attemptNumber)) {
        metrics.retries++;
        final retryAfter = _parseRetryAfter(response);
        final delay = retryAfter ?? _getRetryDelay(attemptNumber);

        if (kDebugMode) {
          debugPrint(
            '[IAHttpClient] Retry attempt ${attemptNumber + 1}/$maxRetries '
            'after ${delay.inSeconds}s (status: ${_getStatusCode(response)})',
          );
        }

        await Future.delayed(delay);
        return _executeWithRetry(
          request,
          timeout: timeout,
          attemptNumber: attemptNumber + 1,
        );
      }

      // Check for HTTP errors
      if (statusCode >= 400) {
        metrics.failures++;
        if (kDebugMode) {
          debugPrint(
            '[IAHttpClient] HTTP error $statusCode: ${_getReasonPhrase(response)}',
          );
        }

        throw IAHttpException(
          'HTTP $statusCode: ${_getReasonPhrase(response)}',
          statusCode: statusCode,
          type: _categorizeError(statusCode),
        );
      }

      return response;
    } on SocketException catch (e) {
      metrics.networkErrors++;
      return _handleNetworkError(e, request, timeout, attemptNumber);
    } on TimeoutException catch (e) {
      metrics.timeouts++;
      metrics.failures++;
      if (kDebugMode) {
        debugPrint('[IAHttpClient] Request timeout: ${e.message}');
      }

      throw IAHttpException(
        'Request timeout: ${e.message}',
        type: IAHttpExceptionType.timeout,
        originalException: e,
      );
    } on IAHttpException {
      rethrow;
    } catch (e) {
      metrics.failures++;
      if (kDebugMode) {
        debugPrint('[IAHttpClient] Unexpected error: $e');
      }

      throw IAHttpException(
        'Unexpected error: $e',
        type: IAHttpExceptionType.unknown,
        originalException: e,
      );
    } finally {
      _rateLimiter.release();
    }
  }

  /// Handle network errors with retry logic.
  Future<T> _handleNetworkError<T>(
    SocketException error,
    Future<T> Function() request,
    Duration? timeout,
    int attemptNumber,
  ) async {
    if (attemptNumber >= maxRetries) {
      metrics.failures++;
      if (kDebugMode) {
        debugPrint(
          '[IAHttpClient] Network error after $maxRetries retries: ${error.message}',
        );
      }

      throw IAHttpException(
        'Network error after $maxRetries retries: ${error.message}',
        type: IAHttpExceptionType.network,
        originalException: error,
      );
    }

    metrics.retries++;
    final delay = _getRetryDelay(attemptNumber);
    if (kDebugMode) {
      debugPrint(
        '[IAHttpClient] Network error, retry ${attemptNumber + 1}/$maxRetries '
        'after ${delay.inSeconds}s: ${error.message}',
      );
    }

    await Future.delayed(delay);
    return _executeWithRetry(
      request,
      timeout: timeout,
      attemptNumber: attemptNumber + 1,
    );
  }

  /// Check if request should be retried based on response.
  bool _shouldRetry(dynamic response, int attemptNumber) {
    if (attemptNumber >= maxRetries) return false;

    final statusCode = _getStatusCode(response);

    // Retry on transient errors
    return statusCode == 429 || // Rate limited
        statusCode == 503 || // Service unavailable
        statusCode == 502 || // Bad gateway
        statusCode == 504; // Gateway timeout
  }

  /// Parse Retry-After header from response.
  ///
  /// Supports both formats per RFC 7231:
  /// - Delay in seconds: "120"
  /// - HTTP-date: "Wed, 21 Oct 2015 07:28:00 GMT"
  Duration? _parseRetryAfter(dynamic response) {
    if (response is! http.Response && response is! http.StreamedResponse) {
      return null;
    }

    final headers = response.headers;
    final retryAfter = headers['retry-after'] ?? headers['Retry-After'];

    if (retryAfter == null) return null;

    // Try parsing as seconds (integer)
    final seconds = int.tryParse(retryAfter);
    if (seconds != null) {
      // Store for UI display
      _lastRetryAfterSeconds = seconds;
      _lastRetryAfterExpiry = DateTime.now().add(Duration(seconds: seconds));
      return Duration(seconds: seconds);
    }

    // Try parsing as HTTP-date (RFC 7231 format)
    try {
      final httpDate = HttpDate.parse(retryAfter);
      final now = DateTime.now();
      final delaySeconds = httpDate.difference(now).inSeconds;

      if (delaySeconds > 0) {
        // Store for UI display
        _lastRetryAfterSeconds = delaySeconds;
        _lastRetryAfterExpiry = httpDate;
        return Duration(seconds: delaySeconds);
      }
    } catch (e) {
      // Invalid date format, fall through to default behavior
      debugPrint('Failed to parse Retry-After date: $retryAfter - $e');
    }

    // Unable to parse, return null and use default exponential backoff
    return null;
  }

  /// Get retry delay for attempt number (exponential backoff).
  Duration _getRetryDelay(int attemptNumber) {
    if (attemptNumber < 0 || attemptNumber >= retryDelays.length) {
      return retryDelays.last; // Max delay
    }
    return retryDelays[attemptNumber];
  }

  /// Merge custom headers with required headers.
  ///
  /// Always includes User-Agent header on native platforms.
  /// On web, User-Agent is not allowed in CORS preflight and is omitted.
  /// Optionally includes If-None-Match header for conditional GET requests.
  Map<String, String> _mergeHeaders(
    Map<String, String>? headers, {
    String? ifNoneMatch,
  }) {
    return {
      // Don't set User-Agent on web - it's not allowed in CORS requests
      if (!kIsWeb) 'User-Agent': userAgent,
      if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
      if (headers != null) ...headers,
    };
  }

  /// Get status code from response (handles both Response and StreamedResponse).
  int _getStatusCode(dynamic response) {
    if (response is http.Response) {
      return response.statusCode;
    } else if (response is http.StreamedResponse) {
      return response.statusCode;
    }
    return 0;
  }

  /// Get reason phrase from response.
  String _getReasonPhrase(dynamic response) {
    if (response is http.Response) {
      return response.reasonPhrase ?? 'Unknown';
    } else if (response is http.StreamedResponse) {
      return response.reasonPhrase ?? 'Unknown';
    }
    return 'Unknown';
  }

  /// Categorize error type based on status code.
  IAHttpExceptionType _categorizeError(int statusCode) {
    if (statusCode == 429) return IAHttpExceptionType.rateLimited;
    if (statusCode >= 500) return IAHttpExceptionType.serverError;
    if (statusCode == 404) return IAHttpExceptionType.notFound;
    if (statusCode >= 400) return IAHttpExceptionType.clientError;
    return IAHttpExceptionType.unknown;
  }

  /// Extract ETag from response headers (for cache validation).
  ///
  /// Returns the ETag value if present, null otherwise.
  /// Archive.org typically returns ETags in the format: `"w/<hash>"` or `"<hash>"`
  static String? extractETag(http.Response response) {
    // Check both 'etag' and 'ETag' (case-insensitive)
    return response.headers['etag'] ??
        response.headers['ETag'] ??
        response.headers['ETAG'];
  }

  /// Get Flutter/Dart version for User-Agent.
  ///
  /// Returns Flutter SDK version (from constant) and Dart SDK version (from Platform.version).
  /// Flutter SDK version is defined as a constant since Flutter doesn't expose it at runtime.
  ///
  /// Format examples:
  /// - Native: "Flutter/3.35.5 Dart/3.8.0"
  /// - Web: "Flutter/3.35.5 (Web)"
  static String _getFlutterVersion() {
    if (kIsWeb) {
      return 'Flutter/$_kFlutterVersion (Web)';
    }

    try {
      // Platform.version includes full Dart version info
      // Format: "3.8.0 (stable) on \"windows_x64\""
      final version = Platform.version;
      final match = RegExp(r'^(\d+\.\d+\.\d+)').firstMatch(version);
      if (match != null) {
        final dartVersion = match.group(1);
        return 'Flutter/$_kFlutterVersion Dart/$dartVersion';
      }
    } catch (e) {
      // Fallback if Platform.version is not available
      debugPrint('Failed to get Dart version: $e');
    }

    return 'Flutter/$_kFlutterVersion';
  }

  /// Get current rate limiter statistics.
  Map<String, dynamic> getStats() {
    return _rateLimiter.getStats();
  }

  /// Get current rate limiter status for UI display.
  RateLimitStatus getRateLimitStatus() {
    // Clear expired retry-after data
    if (_lastRetryAfterExpiry != null &&
        DateTime.now().isAfter(_lastRetryAfterExpiry!)) {
      _lastRetryAfterSeconds = null;
      _lastRetryAfterExpiry = null;
    }

    return RateLimitStatus.fromRateLimiter(
      activeCount: _rateLimiter.activeCount,
      queueLength: _rateLimiter.queueLength,
      maxConcurrent: _rateLimiter.maxConcurrent,
      retryAfterSeconds: _lastRetryAfterSeconds,
      retryAfterExpiry: _lastRetryAfterExpiry,
    );
  }

  /// Close the HTTP client and release resources.
  void close() {
    _innerClient.close();
  }

  /// Get current metrics
  HttpClientMetrics getMetrics() => metrics;

  /// Reset metrics to zero
  void resetMetrics() {
    metrics.requests = 0;
    metrics.retries = 0;
    metrics.failures = 0;
    metrics.timeouts = 0;
    metrics.rateLimitHits = 0;
    metrics.networkErrors = 0;
    metrics.cacheHits = 0;
    metrics.serverErrors = 0;
    if (kDebugMode) {
      debugPrint('[IAHttpClient] Metrics reset');
    }
  }

  /// Get formatted statistics for monitoring
  Map<String, dynamic> getFormattedStatistics() {
    final successfulRequests = metrics.requests - metrics.failures;
    final successRate = metrics.requests > 0
        ? (successfulRequests / metrics.requests * 100).toStringAsFixed(1)
        : '0.0';
    
    final retryRate = metrics.requests > 0
        ? (metrics.retries / metrics.requests * 100).toStringAsFixed(1)
        : '0.0';
    
    final cacheHitRate = metrics.requests > 0
        ? (metrics.cacheHits / metrics.requests * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'totalRequests': metrics.requests,
      'successfulRequests': successfulRequests,
      'failedRequests': metrics.failures,
      'successRate': '$successRate%',
      'retries': metrics.retries,
      'retryRate': '$retryRate%',
      'timeouts': metrics.timeouts,
      'rateLimitHits': metrics.rateLimitHits,
      'networkErrors': metrics.networkErrors,
      'serverErrors': metrics.serverErrors,
      'cacheHits': metrics.cacheHits,
      'cacheHitRate': '$cacheHitRate%',
    };
  }
}

/// Exception thrown by IAHttpClient.
class IAHttpException implements Exception {
  final String message;
  final int? statusCode;
  final IAHttpExceptionType type;
  final Object? originalException;

  const IAHttpException(
    this.message, {
    this.statusCode,
    required this.type,
    this.originalException,
  });

  /// Whether this is a transient error that can be retried.
  bool get isTransient =>
      type == IAHttpExceptionType.rateLimited ||
      type == IAHttpExceptionType.serverError ||
      type == IAHttpExceptionType.network ||
      type == IAHttpExceptionType.timeout;

  @override
  String toString() {
    final buffer = StringBuffer('IAHttpException: $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    buffer.write(' [type: ${type.name}]');
    return buffer.toString();
  }
}

/// Types of HTTP exceptions.
enum IAHttpExceptionType {
  rateLimited,
  serverError,
  clientError,
  notFound,
  network,
  timeout,
  unknown,
}
