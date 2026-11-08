# Android Permissions Documentation

This document details all permissions used by IA Helper and their justifications for Google Play Store compliance.

## Permission Strategy (Nov 2026, issues #81/#82)

IA Helper requests **no dangerous permissions at runtime**:

- **App-scoped storage only**: every download, cache and preview write goes to app-owned directories (see the destination map below), writable on every supported Android version (API 21+) with **no storage permission**.
- **No media library access**: nothing in the app or its dependency tree reads the shared media collections, so no `READ_MEDIA_*` permissions are declared.
- **One runtime permission for notifications (#92)**: download progress + completion notifications declare `POST_NOTIFICATIONS` (Android 13+), requested in-context at the first download of a session - never at launch. On Android 12 and below the master notification toggle applies and no runtime grant exists.
- **Public-folder exports** (planned, #90) will use `ACTION_OPEN_DOCUMENT_TREE` (SAF) with persistable URI grants — also permission-free.

## Required Permissions

### 1. INTERNET (Normal Permission)
- **Permission**: `android.permission.INTERNET`
- **Protection Level**: Normal (granted automatically)
- **Purpose**: Download files from Internet Archive (archive.org)
- **Justification**: Core functionality - the app downloads files from the archive.org API
- **Play Store**: Always approved for download manager apps

### 2. ACCESS_NETWORK_STATE (Normal Permission)
- **Permission**: `android.permission.ACCESS_NETWORK_STATE`
- **Protection Level**: Normal (granted automatically)
- **Purpose**: Detect connection type and availability (connectivity_plus)
- **Justification**: Pause downloads on connection loss, resume when connectivity returns, avoid wasted cellular data
- **Play Store**: Standard for download manager apps

### 3. POST_NOTIFICATIONS (Android 13+ runtime permission, #92)
- **Permission**: `android.permission.POST_NOTIFICATIONS`
- **Protection Level**: Dangerous (runtime grant on API 33+; not a runtime permission on older versions)
- **Purpose**: Show download progress and completion/error notifications
- **Request**: In-context at the first download of a session (PermissionUtils via permission_handler); at most one system prompt per session; never at launch
- **Behavior if denied**: Downloads proceed normally; notifications are silently skipped. No feature is lost, only the convenience of shade notifications.
- **Play Store**: Standard for download manager apps; declared in the main manifest and intentionally kept in the production flavor (unlike media/storage permissions), since the feature ships in the same release (#92)

## Dev/Staging-Only Permission

### MANAGE_EXTERNAL_STORAGE (Android 11+, special access)
- Declared in the main manifest for **dev/staging builds only**.
- The **production flavor removes it** via the `src/production/AndroidManifest.xml` overlay (`tools:node="remove"`), so the Play build ships without it (issue #75, Option B).
- Never requested at runtime (the request helpers were removed in #81). A developer can grant it manually in Settings to test broad-access edge cases.

## Permissions Removed (Nov 2026)

| Permission / flag | Removed by | Rationale |
|---|---|---|
| `POST_NOTIFICATIONS` | #81 | No notification code in the app; the declaration plus launch-time request was pure first-launch friction. **Re-added in #92** together with the notifications feature, requested in-context at first download. |
| `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` | #81 | Nothing in the app or its dependency tree can read the media library; the Android 13+ media gate blocked downloads behind scary prompts for nothing. |
| `READ_MEDIA_VISUAL_USER_SELECTED` | #81 | Same. |
| `WRITE_EXTERNAL_STORAGE` (was maxSdk 32) | #82 | Every write is app-scoped on API 21-33+; the legacy grant served no code path, so it was removed entirely rather than tightened. |
| `READ_EXTERNAL_STORAGE` (was maxSdk 32) | #82 | Resume/checksum reads operate on app-scoped files; FileProvider/open_file need no permission for app-provided files. |
| `requestLegacyExternalStorage="true"` | #82 | Only changes behavior for legacy public-dir writes on Android 10; the app makes none. |
| `android:largeHeap="true"` | #82 | Memory smell; image decode is native-backed and checksum/preview paths stream instead of loading whole files into the Dart heap. On-device spot-check of large PDF/image previews is tracked in #82. |
| `android:autoVerify` on launcher + `iaget://` filters | #82 | App Links verification applies to http/https filters only; the attribute was inert there. Kept on the two archive.org https filters. |

## Storage Destination Map (audit #82)

| Code path | API | Destination | Permission needed |
|---|---|---|---|
| `FileUtils.getDefaultDownloadDirectory()` -> `getExternalStorageDirectory()` | 21+ | `Android/data/<pkg>/files/ia-get` (downloads) | none |
| `StorageAdapter` (native) -> `getApplicationCacheDirectory()` / `getApplicationDocumentsDirectory()` | 21+ | app cache / documents | none |
| `video_preview_widget` -> `getTemporaryDirectory()` | 21+ | app cache | none |
| `archive_preview_widget` -> `getApplicationDocumentsDirectory()` | 21+ | app documents | none |

Verified by code search (Nov 2026): no `getExternalStoragePublicDirectory`, no `getDownloadsDirectory`, no MediaStore usage, no raw `/storage/emulated/0/...` writes anywhere in the codebase.

## Permission Request Flow

App launch prompts for **zero permissions**. The only runtime prompt in the app is the Android 13+ POST_NOTIFICATIONS dialog (#92), shown in-context at the first download of a session (once per session, never nagging; historical storage-prompt flows were removed with #81/#82).

## User Control & Privacy

- No dangerous permissions to revoke in Settings on production builds (only the dev-only All-Files-Access toggle exists on dev/staging builds).
- No data collection, no analytics or crash-reporting SDKs; all state stays on device. Play Console vitals provide crash visibility without shipping code.
- Downloaded files live in app-scoped storage; users share/export them via the in-app share flow (FileProvider) with no permission.

## Play Store Compliance Checklist

- [x] Only permissions with clear, user-facing justification
- [x] No storage or media permissions
- [x] Production permission report: INTERNET + ACCESS_NETWORK_STATE + POST_NOTIFICATIONS (#92, in-context request)
- [x] Dev-only MANAGE_EXTERNAL_STORAGE stripped from production (#75)
- [x] Data-safety form: no data collected

## Future Considerations

- **Download-location picker (#90)**: SAF `ACTION_OPEN_DOCUMENT_TREE`; no new permissions.

## Developer Contact

- Email: admin@historylabs.dev
- GitHub Issues: github.com/gameaday/ia-helper/issues

---

**Last Updated**: November 2026  
**App Version**: 1.9.0-dev  
**Target SDK**: 36 (Android 16)  
**Min SDK**: 21 (Android 5.0)  
**Status**: One optional runtime prompt (POST_NOTIFICATIONS on Android 13+, in-context at first download, #92); none at launch
