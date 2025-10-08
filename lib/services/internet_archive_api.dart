import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../models/archive_metadata.dart';
import '../models/search_result.dart';
import '../core/constants/internet_archive_constants.dart';
import '../core/errors/ia_exceptions.dart';
import '../utils/identifier_validator.dart';
import 'ia_http_client.dart';
import 'rate_limiter.dart';
import 'bandwidth_throttle.dart';
import 'metadata_cache.dart';

/// Pure Dart/Flutter implementation of Internet Archive API client
///
/// This replaces the Rust FFI implementation with native Dart code for:
/// - Metadata fetching from archive.org JSON API
/// - File downloads with progress tracking
/// - Checksum validation
/// - Rate limiting and error handling
///
/// API Reference: https://archive.org/developers/md-read.html
/// 
/// Compliance:
/// - Respects rate limits (max 30 requests/minute) via RateLimiter
/// - Includes proper User-Agent header with contact info via IAHttpClient
/// - Implements exponential backoff for retries via IAHttpClient
/// - Handles all IA-specific HTTP status codes
/// - Bandwidth throttling for downloads via BandwidthThrottle
/// - ETag caching for metadata via MetadataCache
class InternetArchiveApi {
  final IAHttpClient _client;
  final MetadataCache? _cache;
  final BandwidthThrottle? _bandwidthThrottle;
  
  /// App version for User-Agent header
  static const String _appVersion = '1.6.0';

  /// Expose the HTTP client for rate limit status
  IAHttpClient get client => _client;

  InternetArchiveApi({
    IAHttpClient? client,
    MetadataCache? cache,
    BandwidthThrottle? bandwidthThrottle,
  }) : _client = client ?? IAHttpClient(rateLimiter: archiveRateLimiter),
       _cache = cache,
       _bandwidthThrottle = bandwidthThrottle;

  /// Fetch metadata for an Internet Archive item
  ///
  /// [identifier] can be:
  /// - A simple identifier: "commute_test"
  /// - A details URL: "https://archive.org/details/commute_test"
  /// - A metadata URL: "https://archive.org/metadata/commute_test"
  ///
  /// Returns the parsed [ArchiveMetadata] or throws an exception on error
  ///
  /// Supports ETag caching if MetadataCache is provided
  Future<ArchiveMetadata> fetchMetadata(String identifier) async {
    final metadataUrl = _getMetadataUrl(identifier);
    
    // Validate identifier format early
    final extractedId = _extractIdentifier(identifier);
    final validationError = IdentifierValidator.validate(extractedId);
    if (validationError != null) {
      // Suggest a correction if possible
      final suggestion = IdentifierValidator.suggestCorrection(extractedId);
      if (suggestion != null) {
        throw FormatException(
            '$validationError. Did you mean "$suggestion"?');
      }
      throw FormatException(validationError);
    }
    
    if (kDebugMode) {
      print('[InternetArchiveApi] Fetching metadata from: $metadataUrl');
    }

    try {
      // Check for cached ETag if cache is available
      String? etag;
      if (_cache != null) {
        etag = await _cache.getETag(extractedId);
        if (kDebugMode && etag != null) {
          print('[InternetArchiveApi] Found cached ETag: $etag');
        }
      }

      // Use IAHttpClient.get with ETag support
      final response = await _client.get(
        Uri.parse(metadataUrl),
        ifNoneMatch: etag,
      );

      // Handle 304 Not Modified - return cached data
      if (response.statusCode == 304) {
        if (kDebugMode) {
          print('[InternetArchiveApi] Cache hit (304 Not Modified)');
        }
        
        // Get cached metadata
        if (_cache != null) {
          final cached = await _cache.getCachedMetadata(extractedId);
          if (cached != null) {
            return cached.metadata;
          }
        }
        
        // Fallback: cache returned 304 but we don't have the data
        // This shouldn't happen, but handle it gracefully
        throw const IAHttpException(
          'Server returned 304 but no cached data available',
          statusCode: 304,
          type: IAHttpExceptionType.serverError,
        );
      }

      // Handle success
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final metadata = ArchiveMetadata.fromJson(jsonData);
        
        // Update cache with new ETag if available
        if (_cache != null) {
          final newEtag = IAHttpClient.extractETag(response);
          if (newEtag != null) {
            await _cache.updateETag(extractedId, newEtag);
            if (kDebugMode) {
              print('[InternetArchiveApi] Updated ETag in cache: $newEtag');
            }
          }
        }
        
        return metadata;
      }

      // Handle errors
      if (response.statusCode == 404) {
        throw ItemNotFoundException(extractedId);
      } else if (response.statusCode == 403) {
        throw AccessForbiddenException(extractedId);
      }

      // Other errors
      throw IAHttpException(
        'Failed to fetch metadata: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        type: response.statusCode >= 500
            ? IAHttpExceptionType.serverError
            : IAHttpExceptionType.clientError,
      );
    } on IAHttpException {
      rethrow;
    } on ItemNotFoundException {
      rethrow;
    } on AccessForbiddenException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[InternetArchiveApi] Error fetching metadata: $e');
      }
      throw IAHttpException(
        'Failed to fetch metadata: ${e.toString()}',
        type: IAHttpExceptionType.network,
      );
    }
  }

  /// Download a file from a URL with progress tracking and bandwidth throttling
  ///
  /// [url] - Full URL to the file
  /// [outputPath] - Local path where file should be saved
  /// [onProgress] - Optional callback for progress updates (downloaded, total)
  /// [cancellationToken] - Optional token to cancel the download
  /// [useReducedPriority] - Optional flag to mark download as lower priority
  ///                        If null, will auto-detect based on file size (>50MB)
  ///                        Set to true to be a good citizen for large downloads
  ///
  /// Returns the path to the downloaded file
  /// Throws exception on failure
  ///
  /// Uses BandwidthThrottle for rate control and supports X-Accept-Reduced-Priority
  /// header to reduce strain on Internet Archive servers.
  ///
  /// See: https://archive.org/developers/iarest.html#custom-headers
  Future<String> downloadFile(
    String url,
    String outputPath, {
    void Function(int downloaded, int total)? onProgress,
    CancellationToken? cancellationToken,
    bool? useReducedPriority,
  }) async {
    if (kDebugMode) {
      print('[InternetArchiveApi] Downloading from: $url');
      print('[InternetArchiveApi] Saving to: $outputPath');
    }

    try {
      // Use HEAD request to get content length first
      final headResponse = await _client.head(Uri.parse(url));
      final contentLength = int.tryParse(
            headResponse.headers['content-length'] ?? '') ??
          0;

      if (kDebugMode) {
        print('[InternetArchiveApi] Content length: $contentLength bytes');
      }

      // Determine if we should use reduced priority
      // Priority logic:
      // 1. If explicitly set by caller, use that
      // 2. If file is large (>50MB) and auto-reduce is enabled, use reduced priority
      // 3. Otherwise, use default setting
      bool shouldReducePriority = useReducedPriority ??
          (IADownloadPriority.autoReduceLargeFiles &&
              contentLength >= IADownloadPriority.largeSizeThresholdBytes) ||
          IADownloadPriority.defaultReducedPriority;

      if (shouldReducePriority && kDebugMode) {
        print('[InternetArchiveApi] Using reduced priority (good citizen mode)');
      }

      // Use IAHttpClient's GET for retry/rate-limit, but we need streaming
      // For now, use a simple streaming approach with the same headers
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'User-Agent':
            'ia-get/$_appVersion (https://github.com/Gameaday/ia-get-cli)',
      });

      // Add reduced priority header if requested
      if (shouldReducePriority) {
        request.headers[IAHeaders.reducedPriorityHeader] =
            IAHeaders.reducedPriorityValue;
      }

      // Use plain http client for streaming (IAHttpClient handles rate limiting via RateLimiter)
      // We create a temporary client for the download
      final streamClient = http.Client();
      try {
        final streamedResponse = await streamClient.send(request);

        if (streamedResponse.statusCode != 200) {
          await streamedResponse.stream.drain();
          throw IAHttpException(
            'Failed to download file: HTTP ${streamedResponse.statusCode}',
            statusCode: streamedResponse.statusCode,
            type: streamedResponse.statusCode >= 500
                ? IAHttpExceptionType.serverError
                : IAHttpExceptionType.clientError,
          );
        }
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);

        final sink = outputFile.openWrite();
        int downloaded = 0;

        try {
          await for (final chunk in streamedResponse.stream) {
            // Check cancellation
            if (cancellationToken?.isCancelled ?? false) {
              throw Exception('Download cancelled by user');
            }

            // Apply bandwidth throttling if available
            if (_bandwidthThrottle != null) {
              await _bandwidthThrottle.consume(chunk.length);
            }

            sink.add(chunk);
            downloaded += chunk.length;

            // Report progress
            onProgress?.call(downloaded, contentLength);
          }

          await sink.flush();
          await sink.close();

          if (kDebugMode) {
            print('[InternetArchiveApi] Download complete: $outputPath');
          }

          return outputPath;
        } catch (e) {
          await sink.close();
          // Clean up partial download
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
          rethrow;
        }
      } finally {
        streamClient.close();
      }
    } on IAHttpException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[InternetArchiveApi] Download error: $e');
      }
      throw IAHttpException(
        'Failed to download file: ${e.toString()}',
        type: IAHttpExceptionType.network,
      );
    }
  }

  /// Validate file checksum
  ///
  /// [filePath] - Path to the file to validate
  /// [expectedHash] - Expected hash value (hex string)
  /// [hashType] - Hash algorithm: 'md5', 'sha1', or 'sha256'
  ///
  /// Returns true if hash matches, false otherwise
  Future<bool> validateChecksum(
    String filePath,
    String expectedHash,
    String hashType,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    if (kDebugMode) {
      print('Validating $hashType checksum for: $filePath');
    }

    final bytes = await file.readAsBytes();
    Digest digest;

    switch (hashType.toLowerCase()) {
      case 'md5':
        digest = md5.convert(bytes);
        break;
      case 'sha1':
        digest = sha1.convert(bytes);
        break;
      case 'sha256':
        digest = sha256.convert(bytes);
        break;
      default:
        throw Exception('Unsupported hash type: $hashType');
    }

    final actualHash = digest.toString();
    final matches = actualHash.toLowerCase() == expectedHash.toLowerCase();

    if (kDebugMode) {
      print('Expected: $expectedHash');
      print('Actual:   $actualHash');
      print('Match: $matches');
    }

    return matches;
  }

  /// Decompress/extract an archive file
  ///
  /// Supports ZIP, TAR, TAR.GZ, and GZ file formats.
  /// Returns list of extracted file paths.
  /// 
  /// Throws [FileSystemException] if file doesn't exist or directory can't be created.
  /// Throws [FormatException] if archive format is unsupported or corrupted.
  Future<List<String>> decompressFile(
    String archivePath,
    String outputDir,
  ) async {
    final file = File(archivePath);
    
    if (!await file.exists()) {
      throw FileSystemException('Archive file not found', archivePath);
    }

    // Create output directory if it doesn't exist
    final outDir = Directory(outputDir);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    // Get just the filename without path
    final fileName = path.basename(file.path).toLowerCase();
    final bytes = await file.readAsBytes();
    
    if (kDebugMode) {
      print('Decompressing: $archivePath');
      print('Output directory: $outputDir');
      print('File size: ${bytes.length} bytes');
    }

    final extractedFiles = <String>[];

    try {
      if (fileName.endsWith('.zip')) {
        // Handle ZIP archives
        final archive = ZipDecoder().decodeBytes(bytes);
        extractedFiles.addAll(await _extractArchive(archive, outputDir));
        
      } else if (fileName.endsWith('.tar.gz') || fileName.endsWith('.tgz')) {
        // Handle TAR.GZ archives
        final gzipBytes = const GZipDecoder().decodeBytes(bytes);
        final archive = TarDecoder().decodeBytes(gzipBytes);
        extractedFiles.addAll(await _extractArchive(archive, outputDir));
        
      } else if (fileName.endsWith('.tar')) {
        // Handle TAR archives
        final archive = TarDecoder().decodeBytes(bytes);
        extractedFiles.addAll(await _extractArchive(archive, outputDir));
        
      } else if (fileName.endsWith('.gz')) {
        // Handle single GZIP files
        final decompressed = const GZipDecoder().decodeBytes(bytes);
        // Extract just the filename without the .gz extension
        String baseFileName = fileName.substring(0, fileName.length - 3);
        final outputPath = path.join(outputDir, baseFileName);
        
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(decompressed);
        extractedFiles.add(outputPath);
        
      } else {
        throw FormatException(
          'Unsupported archive format. Supported: .zip, .tar, .tar.gz, .tgz, .gz',
          fileName,
        );
      }

      if (kDebugMode) {
        print('Successfully extracted ${extractedFiles.length} file(s)');
      }

      return extractedFiles;
      
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Failed to decompress archive: ${e.toString()}', archivePath);
    }
  }

  /// Extract files from an Archive object to the output directory
  Future<List<String>> _extractArchive(Archive archive, String outputDir) async {
    final extractedFiles = <String>[];

    for (final file in archive) {
      if (file.isFile) {
        final outputPath = path.join(outputDir, file.name);
        
        // Create parent directories if needed
        final outputFile = File(outputPath);
        if (!await outputFile.parent.exists()) {
          await outputFile.parent.create(recursive: true);
        }

        // Write file content
        await outputFile.writeAsBytes(file.content as List<int>);
        extractedFiles.add(outputPath);
        
        if (kDebugMode) {
          print('Extracted: ${file.name} (${file.size} bytes)');
        }
      }
    }

    return extractedFiles;
  }

  /// Suggest alternative identifiers when the original one is not found
  ///
  /// Checks:
  /// 1. If identifier has uppercase letters, try lowercase version
  /// 2. Search for similar identifiers
  ///
  /// Returns a list of SearchResult suggestions
  Future<List<SearchResult>> suggestAlternativeIdentifiers(String identifier) async {
    final suggestions = <SearchResult>[];
    
    // Check if identifier has uppercase letters
    if (identifier != identifier.toLowerCase()) {
      final lowercaseId = identifier.toLowerCase();
      
      try {
        // Try to fetch metadata with lowercase identifier
        final testUrl = _getMetadataUrl(lowercaseId);
        final testResponse = await _client
            .get(
              Uri.parse(testUrl),
              headers: IAHeaders.standard(_appVersion),
            )
            .timeout(const Duration(seconds: 5));
        
        if (testResponse.statusCode == 200) {
          // Parse the response to get title
          try {
            final jsonData = json.decode(testResponse.body);
            final title = jsonData['metadata']?['title'] ?? 'Untitled';
            final titleStr = title is List ? (title.isNotEmpty ? title.first.toString() : 'Untitled') : title.toString();
            
            suggestions.add(SearchResult(
              identifier: lowercaseId,
              title: titleStr,
              description: 'Did you mean this? (identifiers are case-sensitive)',
            ));
          } catch (_) {
            // If parsing fails, still add a basic suggestion
            suggestions.add(SearchResult(
              identifier: lowercaseId,
              title: lowercaseId,
              description: 'Did you mean this? (identifiers are case-sensitive)',
            ));
          }
          
          // Return early with just the lowercase suggestion
          return suggestions;
        }
      } catch (_) {
        // Lowercase version doesn't exist either, continue with search
      }
    }
    
    // Try to find similar identifiers using search
    try {
      final searchUrl = IAUtils.buildSearchUrl(
        query: identifier,
        rows: 5,
        fields: ['identifier', 'title', 'description'],
      );
      
      final searchResponse = await _client
          .get(
            Uri.parse(searchUrl),
            headers: IAHeaders.standard(_appVersion),
          )
          .timeout(const Duration(seconds: 5));
      
      if (searchResponse.statusCode == 200) {
        final jsonData = json.decode(searchResponse.body);
        final docs = jsonData['response']?['docs'] as List<dynamic>? ?? [];
        
        for (final doc in docs.take(5)) {
          try {
            suggestions.add(SearchResult.fromJson(doc as Map<String, dynamic>));
          } catch (_) {
            // Skip if parsing fails
            continue;
          }
        }
      }
    } catch (_) {
      // Search failed, return what we have
    }
    
    return suggestions;
  }

  /// Convert various input formats to metadata URL
  ///
  /// Handles:
  /// - Details URL: https://archive.org/details/identifier
  /// - Metadata URL: https://archive.org/metadata/identifier
  /// - Simple identifier: identifier
  String _getMetadataUrl(String input) {
    final trimmed = input.trim();

    if (trimmed.contains('/details/')) {
      return trimmed.replaceAll('/details/', '/metadata/');
    } else if (trimmed.contains('://${IAEndpoints.base.replaceAll('https://', '')}/metadata/')) {
      return trimmed;
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // It's a URL but not a details or metadata URL - extract identifier
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final identifier = segments.last;
        return IAUtils.buildMetadataUrl(identifier);
      }
      throw Exception('Cannot extract identifier from URL: $trimmed');
    } else {
      // Assume it's a bare identifier - validate it
      if (!IAUtils.isValidIdentifier(trimmed)) {
        throw Exception(IAErrorMessages.invalidIdentifier);
      }
      return IAUtils.buildMetadataUrl(trimmed);
    }
  }

  /// Extract identifier from various input formats
  ///
  /// Handles:
  /// - Details URL: https://archive.org/details/identifier -> identifier
  /// - Metadata URL: https://archive.org/metadata/identifier -> identifier
  /// - Simple identifier: identifier -> identifier
  String _extractIdentifier(String input) {
    final trimmed = input.trim();

    if (trimmed.contains('/details/')) {
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments;
      final detailsIndex = segments.indexOf('details');
      if (detailsIndex >= 0 && detailsIndex < segments.length - 1) {
        return segments[detailsIndex + 1];
      }
    } else if (trimmed.contains('/metadata/')) {
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments;
      final metadataIndex = segments.indexOf('metadata');
      if (metadataIndex >= 0 && metadataIndex < segments.length - 1) {
        return segments[metadataIndex + 1];
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // It's a URL but not a details or metadata URL - extract last segment
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    
    // Assume it's a bare identifier
    return trimmed;
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Simple cancellation token for downloads
class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Exception thrown when an archive item is not found
class NotFoundException implements Exception {
  final String identifier;
  
  NotFoundException(this.identifier);
  
  @override
  String toString() => 'Archive item "$identifier" not found (404)';
}

/// Exception thrown when access is forbidden
class ForbiddenException implements Exception {
  final String message;
  
  ForbiddenException(this.message);
  
  @override
  String toString() => 'Access forbidden (403): $message';
}

/// Exception thrown when the service is unavailable
class ServiceUnavailableException implements Exception {
  final String message;
  
  ServiceUnavailableException(this.message);
  
  @override
  String toString() => 'Service unavailable (503): $message';
}
