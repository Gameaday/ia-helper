import 'dart:io';
import 'package:flutter/foundation.dart';

/// Error types for categorizing different kinds of failures
enum ErrorType {
  /// Network connectivity issues
  network,

  /// Request timeout
  timeout,

  /// HTTP 404 - Resource not found
  notFound,

  /// HTTP 429 - Rate limit exceeded
  rateLimit,

  /// HTTP 5xx - Server errors
  server,

  /// HTTP 403 - Forbidden/Access denied
  forbidden,

  /// HTTP 400 - Bad request
  badRequest,

  /// Unknown or uncategorized error
  unknown,
}

/// Detailed error information with user-friendly messaging
class ErrorInfo {
  final ErrorType type;
  final String message;
  final String? suggestion;
  final bool canRetry;
  final Duration? retryDelay;

  const ErrorInfo({
    required this.type,
    required this.message,
    this.suggestion,
    required this.canRetry,
    this.retryDelay,
  });
}

/// Comprehensive error handler with retry logic and user-friendly messaging
class ErrorHandler {
  ErrorHandler._();

  /// Parse an exception and return detailed error information
  static ErrorInfo parseError(dynamic error) {
    if (kDebugMode) {
      debugPrint('[ErrorHandler] Parsing error: $error');
    }

    // Network connectivity errors
    if (error is SocketException) {
      return const ErrorInfo(
        type: ErrorType.network,
        message: 'No internet connection',
        suggestion:
            'Please check your internet connection and try again. Make sure you\'re connected to Wi-Fi or mobile data.',
        canRetry: true,
        retryDelay: Duration(seconds: 2),
      );
    }

    // Timeout errors
    if (error.toString().toLowerCase().contains('timeout') ||
        error.toString().toLowerCase().contains('timed out')) {
      return const ErrorInfo(
        type: ErrorType.timeout,
        message: 'Request timed out',
        suggestion:
            'The server is taking too long to respond. This might be due to a slow connection or high server load. Please try again.',
        canRetry: true,
        retryDelay: Duration(seconds: 3),
      );
    }

    // HTTP errors - extract status code
    final errorString = error.toString().toLowerCase();

    // 404 - Not Found
    if (errorString.contains('404') || errorString.contains('not found')) {
      return const ErrorInfo(
        type: ErrorType.notFound,
        message: 'Archive not found',
        suggestion:
            'The requested archive doesn\'t exist or has been removed from the Internet Archive. Please verify the archive identifier.',
        canRetry: false,
      );
    }

    // 429 - Rate Limit
    if (errorString.contains('429') ||
        errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return const ErrorInfo(
        type: ErrorType.rateLimit,
        message: 'Rate limit exceeded',
        suggestion:
            'You\'ve made too many requests. Please wait a moment before trying again. The Internet Archive limits request frequency.',
        canRetry: true,
        retryDelay: Duration(seconds: 30),
      );
    }

    // 403 - Forbidden
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return const ErrorInfo(
        type: ErrorType.forbidden,
        message: 'Access denied',
        suggestion:
            'You don\'t have permission to access this resource. It may be restricted or require authentication.',
        canRetry: false,
      );
    }

    // 400 - Bad Request
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return const ErrorInfo(
        type: ErrorType.badRequest,
        message: 'Invalid request',
        suggestion:
            'The search query or parameters are invalid. Please check your search terms and try again.',
        canRetry: false,
      );
    }

    // 5xx - Server Errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('server error')) {
      return const ErrorInfo(
        type: ErrorType.server,
        message: 'Server error',
        suggestion:
            'The Internet Archive server encountered an error. This is usually temporary. Please try again in a few moments.',
        canRetry: true,
        retryDelay: Duration(seconds: 5),
      );
    }

    // Unknown error
    return const ErrorInfo(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred',
      suggestion:
          'Something went wrong. Please try again. If the problem persists, please check your internet connection.',
      canRetry: true,
      retryDelay: Duration(seconds: 2),
    );
  }

  /// Get a user-friendly error message from an error object
  static String getUserMessage(dynamic error) {
    return parseError(error).message;
  }

  /// Get an actionable suggestion for an error
  static String? getSuggestion(dynamic error) {
    return parseError(error).suggestion;
  }

  /// Check if an error is retryable
  static bool canRetry(dynamic error) {
    return parseError(error).canRetry;
  }

  /// Get the recommended retry delay for an error
  static Duration? getRetryDelay(dynamic error) {
    return parseError(error).retryDelay;
  }
}

/// Retry manager with exponential backoff
class RetryManager {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;

  /// Execute an async function with automatic retry and exponential backoff
  ///
  /// Returns the result of the function if successful, or throws the last error.
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = _maxRetries,
    Duration initialDelay = _initialDelay,
    double backoffMultiplier = _backoffMultiplier,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (kDebugMode) {
          debugPrint('[RetryManager] Attempt $attempt failed: $e');
        }

        // Check if we should retry
        final canRetryError = shouldRetry?.call(e) ?? ErrorHandler.canRetry(e);
        final hasAttemptsLeft = attempt < maxRetries;

        if (!canRetryError || !hasAttemptsLeft) {
          if (kDebugMode) {
            debugPrint(
              '[RetryManager] Not retrying. canRetry: $canRetryError, hasAttempts: $hasAttemptsLeft',
            );
          }
          rethrow;
        }

        // Use error-specific delay if available, otherwise use exponential backoff
        final errorDelay = ErrorHandler.getRetryDelay(e);
        final waitDuration = errorDelay ?? delay;

        if (kDebugMode) {
          debugPrint(
            '[RetryManager] Retrying in ${waitDuration.inSeconds}s (attempt $attempt/$maxRetries)',
          );
        }

        await Future.delayed(waitDuration);

        // Exponential backoff for next attempt
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }
}
