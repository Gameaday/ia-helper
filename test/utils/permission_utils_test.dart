import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/utils/permission_utils.dart';

/// Permission seam regression tests (#86, post-Phase-0 reality).
///
/// Phase 0 (#81/#82) removed every storage permission: all writes go to
/// app-scoped directories, so the storage helpers are stable always-true
/// stubs and these tests pin that contract (a prompt or a `false` here
/// would mean the storage model regressed).
///
/// Notifications (#92) are the one runtime permission left; on the test
/// VM the permission_handler platform channel is unavailable, so both
/// helpers must return `false` WITHOUT throwing - the download flow must
/// never crash because the channel is missing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('storage helpers are always-true stubs (app-scoped model, #81/#82)',
      () async {
    expect(await PermissionUtils.requestStoragePermissions(), isTrue);
    expect(await PermissionUtils.hasStoragePermissions(), isTrue);
    // Repeated calls must never flip to prompting semantics.
    expect(await PermissionUtils.requestStoragePermissions(), isTrue);
    expect(await PermissionUtils.hasStoragePermissions(), isTrue);
  });

  test('notification helpers degrade to false on a channel-less platform',
      () async {
    expect(await PermissionUtils.hasNotificationPermission(), isFalse);
    expect(await PermissionUtils.requestNotificationPermission(), isFalse);
  });

  test('notification request never throws and never nags per session',
      () async {
    // Multiple requests in one session: every one must resolve (not
    // throw, not hang), and stay denied on a channel-less platform.
    for (var i = 0; i < 3; i++) {
      final granted = await PermissionUtils.requestNotificationPermission();
      expect(granted, isFalse);
    }
  });
}
