import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart' as mime;

/// Service for opening files with appropriate external applications
///
/// Supports:
/// - Cross-platform file opening (Android, iOS, desktop)
/// - Automatic MIME type detection
/// - Error handling and user feedback
/// - Directory opening support
class FileOpenerService {
  /// Singleton instance
  static final FileOpenerService instance = FileOpenerService._();
  FileOpenerService._();

  /// Open a file with the system's default application
  ///
  /// Returns a [FileOpenResult] with success status and optional error message.
  Future<FileOpenResult> openFile(String filePath) async {
    try {
      if (kDebugMode) {
        debugPrint('[FileOpenerService] Opening file: $filePath');
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return FileOpenResult(
          success: false,
          message: 'File not found: $filePath',
        );
      }

      // Get MIME type for better app selection
      final mimeType = mime.lookupMimeType(filePath) ?? 'application/octet-stream';
      
      if (kDebugMode) {
        debugPrint('[FileOpenerService] MIME type: $mimeType');
      }

      // Open the file
      final result = await OpenFile.open(
        filePath,
        type: mimeType,
      );

      if (kDebugMode) {
        debugPrint('[FileOpenerService] Result: ${result.type} - ${result.message}');
      }

      // Check result
      if (result.type == ResultType.done) {
        return FileOpenResult(
          success: true,
          message: 'File opened successfully',
        );
      } else if (result.type == ResultType.noAppToOpen) {
        return FileOpenResult(
          success: false,
          message: 'No app found to open this file type',
          canInstallApp: true,
        );
      } else if (result.type == ResultType.permissionDenied) {
        return FileOpenResult(
          success: false,
          message: 'Permission denied to access file',
          needsPermission: true,
        );
      } else if (result.type == ResultType.fileNotFound) {
        return FileOpenResult(
          success: false,
          message: 'File not found',
        );
      } else {
        return FileOpenResult(
          success: false,
          message: result.message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FileOpenerService] Error opening file: $e');
      }
      
      return FileOpenResult(
        success: false,
        message: 'Failed to open file: $e',
      );
    }
  }

  /// Open a directory/folder
  ///
  /// Shows the folder in the system's file manager.
  Future<FileOpenResult> openDirectory(String dirPath) async {
    try {
      if (kDebugMode) {
        debugPrint('[FileOpenerService] Opening directory: $dirPath');
      }

      // Check if directory exists
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return FileOpenResult(
          success: false,
          message: 'Directory not found: $dirPath',
        );
      }

      // On Android, we need to open the directory differently
      if (Platform.isAndroid) {
        // Android doesn't have a standard way to open directories
        // We'll open the parent directory instead
        final result = await OpenFile.open(dirPath);
        
        if (result.type == ResultType.done) {
          return FileOpenResult(
            success: true,
            message: 'Directory opened',
          );
        } else {
          return FileOpenResult(
            success: false,
            message: 'Could not open directory: ${result.message}',
          );
        }
      } else {
        // On desktop platforms, open_file can handle directories
        final result = await OpenFile.open(dirPath);
        
        return FileOpenResult(
          success: result.type == ResultType.done,
          message: result.message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FileOpenerService] Error opening directory: $e');
      }
      
      return FileOpenResult(
        success: false,
        message: 'Failed to open directory: $e',
      );
    }
  }

  /// Get the download directory path for an archive identifier
  Future<String> getArchiveDownloadPath(String identifier) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/downloads/$identifier';
  }

  /// Open the download directory for an archive
  Future<FileOpenResult> openArchiveDirectory(String identifier) async {
    final dirPath = await getArchiveDownloadPath(identifier);
    return openDirectory(dirPath);
  }

  /// Get human-readable file type description from MIME type
  String getFileTypeDescription(String? mimeType) {
    if (mimeType == null) return 'File';

    if (mimeType.startsWith('video/')) return 'Video';
    if (mimeType.startsWith('audio/')) return 'Audio';
    if (mimeType.startsWith('image/')) return 'Image';
    if (mimeType.startsWith('text/')) return 'Text';
    
    if (mimeType.contains('pdf')) return 'PDF Document';
    if (mimeType.contains('zip') || mimeType.contains('archive')) return 'Archive';
    if (mimeType.contains('word')) return 'Word Document';
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return 'Spreadsheet';
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return 'Presentation';
    
    return 'File';
  }
}

/// Result of a file open operation
class FileOpenResult {
  final bool success;
  final String message;
  final bool canInstallApp;
  final bool needsPermission;

  FileOpenResult({
    required this.success,
    required this.message,
    this.canInstallApp = false,
    this.needsPermission = false,
  });

  @override
  String toString() => 'FileOpenResult(success: $success, message: $message)';
}
