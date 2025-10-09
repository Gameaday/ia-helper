import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Platform storage abstraction layer
///
/// Provides a consistent file system API across all platforms.
/// - Native (Android/iOS): Uses real file system via path_provider
/// - Web: Uses in-memory storage (no disk operations)
///
/// This eliminates the need for kIsWeb checks throughout the codebase.
/// Web automatically adapts to mobile's API without special handling.
abstract class StorageAdapter {
  /// Get the application's cache directory
  Future<Directory> getCacheDirectory();

  /// Get the application's documents directory
  Future<Directory> getDocumentsDirectory();

  /// Check if platform supports real file system operations
  bool get supportsFileSystem;

  /// Check if platform has CORS restrictions
  bool get hasCorsRestrictions;

  /// Factory constructor that returns the appropriate implementation
  factory StorageAdapter() {
    if (kIsWeb) {
      return _WebStorageAdapter();
    }
    return _NativeStorageAdapter();
  }
}

/// Native platform implementation (Android/iOS/Desktop)
///
/// Uses real file system via path_provider plugin.
class _NativeStorageAdapter implements StorageAdapter {
  @override
  Future<Directory> getCacheDirectory() async {
    return await path_provider.getApplicationCacheDirectory();
  }

  @override
  Future<Directory> getDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }

  @override
  bool get supportsFileSystem => true;

  @override
  bool get hasCorsRestrictions => false;
}

/// Web platform implementation
///
/// Provides in-memory "virtual" directories that act like real directories
/// but don't actually write to disk. This allows web to seamlessly use
/// mobile's file-based APIs without modification.
///
/// All file operations become no-ops or memory operations:
/// - File.exists() → always returns false (no disk cache on web)
/// - File.readAsBytes() → throws (not needed on web)
/// - File.writeAsBytes() → silently ignored (memory cache handles it)
class _WebStorageAdapter implements StorageAdapter {
  // Virtual directories that exist only in memory
  static const _virtualCache = _VirtualDirectory('/cache');
  static const _virtualDocs = _VirtualDirectory('/documents');

  @override
  Future<Directory> getCacheDirectory() async {
    return _virtualCache;
  }

  @override
  Future<Directory> getDocumentsDirectory() async {
    return _virtualDocs;
  }

  @override
  bool get supportsFileSystem => false;

  @override
  bool get hasCorsRestrictions => true;
}

/// Virtual directory for web platform
///
/// Acts like a Directory but all operations are no-ops.
/// This allows services to call directory methods without crashing on web.
class _VirtualDirectory implements Directory {
  final String _path;

  const _VirtualDirectory(this._path);

  @override
  String get path => _path;

  @override
  Uri get uri => Uri.parse('memory://$_path');

  @override
  Future<bool> exists() async => false; // Always false - no real directory

  @override
  Future<Directory> create({bool recursive = false}) async => this;

  @override
  Directory createSync({bool recursive = false}) => this;

  @override
  Future<Directory> createTemp([String? prefix]) async {
    return const _VirtualDirectory('/tmp');
  }

  @override
  Directory createTempSync([String? prefix]) {
    return const _VirtualDirectory('/tmp');
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;

  @override
  void deleteSync({bool recursive = false}) {}

  @override
  Future<Directory> rename(String newPath) async {
    return const _VirtualDirectory('/renamed');
  }

  @override
  Directory renameSync(String newPath) {
    return const _VirtualDirectory('/renamed');
  }

  @override
  Directory get absolute => this;

  @override
  Future<String> resolveSymbolicLinks() async => _path;

  @override
  String resolveSymbolicLinksSync() => _path;

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return const Stream.empty(); // No files in virtual directory
  }

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return const []; // No files in virtual directory
  }

  @override
  Directory get parent => const _VirtualDirectory('/');

  @override
  Future<FileStat> stat() async {
    // Return a stat indicating "not found"
    return await FileStat.stat(_path);
  }

  @override
  FileStat statSync() {
    // Return a stat indicating "not found"
    return FileStat.statSync(_path);
  }

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) {
    // Return empty stream - no events on virtual directory
    return const Stream.empty();
  }

  // Ignore unsupported operations
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
