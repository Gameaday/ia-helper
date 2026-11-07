/// Runtime permission helpers.
///
/// Storage model (issues #81 / #82, Nov 2026): every download, cache and
/// preview write goes to app-scoped directories (path_provider), which are
/// writable on every supported Android version (API 21+) with NO runtime
/// storage permission. The app therefore declares and requests no storage
/// permissions at all. This class is kept as a stable seam for callers;
/// the planned SAF download-location picker (#90) also needs no permission
/// (persistable URI grants), and download notifications (#92) will
/// re-introduce exactly one runtime permission (POST_NOTIFICATIONS).
class PermissionUtils {
  /// No-op: app-scoped storage requires no runtime grant on any supported
  /// Android version, so nothing is ever prompted. Always returns true.
  static Future<bool> requestStoragePermissions() async => true;

  /// No-op check: always true (see [requestStoragePermissions]).
  static Future<bool> hasStoragePermissions() async => true;
}
