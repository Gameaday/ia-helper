import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of delivering a finished download to the user's chosen
/// public folder (#90). Pure enum so the decision table is testable.
enum SafExportOutcome {
  /// No SAF folder is configured — the default app-scoped storage is
  /// the destination and there is nothing to do.
  notConfigured,

  /// The persistable grant is gone (folder deleted, SD card removed or
  /// the grant otherwise revoked): the app copy stays in app storage
  /// and the user gets a notice. The stored folder is cleared.
  grantRevoked,

  /// The copy into the chosen folder succeeded.
  exported,

  /// The copy failed for another reason (I/O); the app copy is intact
  /// and remains the canonical download.
  failed,
}

/// Storage Access Framework download-location picker (#90).
///
/// Opt-in: by default every download stays in app-scoped storage (the
/// Phase 0 permission model, issues #81/#82 — no storage permissions at
/// all). When the user picks a public folder here, ACTION_OPEN_DOCUMENT_
/// TREE grants a persistable read/write URI grant, which survives
/// restarts and needs NO manifest permission. Finished, checksum-verified
/// downloads are then additionally copied into that folder; the
/// app-scoped copy remains the canonical file for previews, library and
/// archive sync.
///
/// All method calls are best-effort: a missing or revoked folder must
/// never fail a download — the outcome is reported so the caller can
/// surface a notice.
class SafDownloadService {
  SafDownloadService._internal({
    MethodChannel? channel,
    bool Function()? platformCheck,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _platformCheck = platformCheck ?? _defaultPlatformCheck;

  static const String _channelName = 'com.internetarchive.helper/saf';
  static const String prefTreeUri = 'saf_tree_uri';
  static const String prefFolderName = 'saf_folder_name';

  /// Production platform gate: SAF exists only on Android.
  static bool _defaultPlatformCheck() => !kIsWeb && Platform.isAndroid;

  static SafDownloadService? _instance;

  /// Singleton for app use.
  static SafDownloadService get instance =>
      _instance ??= SafDownloadService._internal();

  /// Test factory with an injectable channel and platform gate.
  @visibleForTesting
  factory SafDownloadService.test({
    MethodChannel? channel,
    bool Function()? platformCheck,
  }) => SafDownloadService._internal(
    channel: channel,
    platformCheck: platformCheck,
  );

  final MethodChannel _channel;
  final bool Function() _platformCheck;

  /// The persisted tree URI, or null when the default app storage is
  /// in effect.
  Future<String?> currentTreeUri() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefTreeUri);
    } catch (_) {
      return null;
    }
  }

  /// Human-readable name of the chosen folder, or null.
  Future<String?> currentFolderName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefFolderName);
    } catch (_) {
      return null;
    }
  }

  /// Open the system folder picker (ACTION_OPEN_DOCUMENT_TREE) and
  /// persist the returned grant. Returns the folder name on success,
  /// or null when the user cancelled / the platform can't do it.
  Future<String?> pickFolder() async {
    if (!_platformCheck()) return null;

    final Object? raw;
    try {
      raw = await _channel.invokeMethod('pickFolder');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
    if (raw is! Map) return null;

    final treeUri = raw['treeUri'] as String?;
    final folderName = raw['folderName'] as String?;
    if (treeUri == null || treeUri.isEmpty) return null;

    // Replacing a previous choice: release the old grant.
    await _releaseStoredGrant();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefTreeUri, treeUri);
    await prefs.setString(prefFolderName, folderName ?? treeUri);
    return folderName ?? treeUri;
  }

  /// Whether the stored folder still has a valid persistable grant.
  Future<bool> hasValidGrant() async {
    final treeUri = await currentTreeUri();
    if (treeUri == null) return false;
    try {
      final ok = await _channel.invokeMethod('hasValidGrant', {
        'treeUri': treeUri,
      });
      return ok == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Forget the chosen folder and release its grant; downloads return
  /// to the default app-scoped storage.
  Future<void> clearFolder() async {
    await _releaseStoredGrant();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefTreeUri);
      await prefs.remove(prefFolderName);
    } catch (_) {
      // Preferences unavailable (test VM): the grant release above is
      // the meaningful part.
    }
  }

  Future<void> _releaseStoredGrant() async {
    final treeUri = await currentTreeUri();
    if (treeUri == null) return;
    try {
      await _channel.invokeMethod('releaseGrant', {'treeUri': treeUri});
    } catch (_) {
      // The grant may already be gone; releasing is best-effort.
    }
  }

  /// Copy a finished download into the chosen folder.
  ///
  /// Never throws: the app-scoped copy always remains intact, and the
  /// outcome tells the caller whether a fallback notice is needed.
  Future<SafExportOutcome> exportFile(
    String localFilePath, {
    String? fileName,
  }) async {
    if (!_platformCheck()) return SafExportOutcome.notConfigured;

    final treeUri = await currentTreeUri();
    if (treeUri == null) return SafExportOutcome.notConfigured;

    bool valid;
    try {
      final ok = await _channel.invokeMethod('hasValidGrant', {
        'treeUri': treeUri,
      });
      valid = ok == true;
    } on MissingPluginException {
      return SafExportOutcome.notConfigured;
    } on PlatformException {
      valid = false;
    }

    if (!valid) {
      // The folder is gone or the grant was revoked: stop offering the
      // destination and tell the caller to fall back to app storage.
      await clearFolder();
      return SafExportOutcome.grantRevoked;
    }

    final name = fileName ??
        (localFilePath.contains('/')
            ? localFilePath.split('/').last
            : localFilePath);
    if (name.isEmpty) return SafExportOutcome.failed;

    try {
      await _channel.invokeMethod('exportFile', {
        'treeUri': treeUri,
        'filePath': localFilePath,
        'fileName': name,
        'mimeType': lookupMimeType(name) ?? 'application/octet-stream',
      });
      return SafExportOutcome.exported;
    } on MissingPluginException {
      return SafExportOutcome.failed;
    } on PlatformException {
      return SafExportOutcome.failed;
    }
  }
}
