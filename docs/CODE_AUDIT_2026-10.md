# IA Helper — Code Audit (October 2026)

Pre-launch correctness pass over the download engine, storage/permission layer, and supporting
services. Companion to `PRELAUNCH_AUDIT.md` (store readiness) — this file covers code quality.

Method: full read of `download_scheduler.dart`, `resumable_download_service.dart`,
`download_provider.dart`, `archive_service.dart`, `database_helper.dart`, `permission_utils.dart`,
`main.dart`, and the FileFilter model. Safe fixes were applied in the same commit as this doc;
judgement calls are flagged below or filed as issues.

## Verdict

The architecture is sound: clean provider/service separation, a single versioned SQLite source of
truth (migrations v1–v6 are correct and additive), resumable downloads with ETag validation, and
graceful permission degradation. Everything found was an implementation slip, not a design flaw.
Eleven concrete bugs are fixed in this commit; one high-severity item (Android version detection)
needs a dependency decision and is filed as issue #77.

## Fixed in this commit

| # | Severity | Where | Bug | Fix |
|---|----------|-------|-----|-----|
| 1 | High | scheduler `_tick()` | Unbounded rotation: a queue of not-ready tasks (scheduled/backoff) spins the sync while-loop forever, freezing the event loop | One-full-rotation guard |
| 2 | High | scheduler `_handleProgressUpdate` | Every active download was reported with the SAME task's progress | Per-task progress map |
| 3 | High | provider `_executeDownload` | Concurrency counter incremented after the metadata fetch → parallel `startDownload` calls bypass the limit; early failure corrupted the counter | Increment before first await |
| 4 | High | resumable service | Server ignoring Range (HTTP 200) while a partial file exists → dio appends the full body to the partial → corrupt file, then retries from a bogus offset forever | Detect 200-after-Range → delete partial, restart from 0 |
| 5 | Medium | resumable service | Resume progress percentage used remaining bytes as the total | total = startByte + received-total |
| 6 | Medium | provider `retryDownload` | Passed the archive identifier as `outputDir` → files written to a bogus relative path | Retry uses the default output dir |
| 7 | Medium | provider `retryDownload` | `copyWith(error: null)` cannot clear the old error → retried downloads kept a stale error message | Fresh `DownloadState` on retry |
| 8 | Medium | provider `cancelDownload` | Cancelling a QUEUED download left it in `_downloadQueue`; `_processQueue()` started it later anyway | Remove from queue on cancel |
| 9 | Medium | provider statistics | `_totalDownloadsCompleted` / `_totalBytesDownloaded` were `final` → always 0 | Mutable, incremented on completion |
| 10 | Medium | scheduler `dispose()` | Closed the broadcast StreamControllers → any later `initialize()` threw "add after closing" | Singleton no longer closes controllers |
| 11 | Low | resumable service | `receivedBytes % 1MB == 0` almost never true with chunked callbacks → `partialBytes` rarely persisted | Persist every 5 MB |

## Flagged — need Carl's decision or on-device testing

### HIGH — Android version detection (issue #77)
`_isAndroid13OrHigher()` returns true whenever `Permission.photos.status` does not throw — which is
always. On Android 10–12 the app therefore never requests WRITE_EXTERNAL_STORAGE /
MANAGE_EXTERNAL_STORAGE, and storage access can become ungrantable. Fix requires a real SDK_INT
check (`device_info_plus` or a small MethodChannel) — filed with a fix sketch; not changed blindly
because it adds a dependency. Ties into #75 (storage strategy).

### Design — two download pipelines
`DownloadProvider` (in-memory queue driving the UI) and `DownloadScheduler` (persistent
SQLite-backed queue behind the Transfers screen) are parallel engines with overlapping
responsibilities (priority, retry, concurrency). Fine for 1.0 — but consolidate onto the
scheduler as the single engine post-1.0 to avoid divergent queue behavior.

### Design — checksum failures are silent
In the provider loop a failed MD5 validation is caught and only debug-printed; the file is kept
and the download marked complete. Recommend surfacing a per-file warning state. Not a launch
blocker (IA serves MD5s and mismatches are rare), but worth a follow-up issue post-1.0.

### Design — cancel does not propagate
`cancelDownload` updates state, but an in-flight file copy continues to completion (the code
comment acknowledges this). Clean fix: cancel token threaded into `ArchiveService.downloadFile`.
Post-1.0.

### Low / cosmetic
- `_formatSize` is duplicated in ≥5 widgets while `lib/core/extensions/num_extensions.dart`
  already provides `toFileSize` — DRY pass when convenient.
- sqflite does not enable `PRAGMA foreign_keys`, so `ON DELETE CASCADE` on `collection_items`
  never fires (deletes are done manually today, so no live bug — just don't rely on it).
- `_isArchive()` treats every `.gz` as an extractable archive, including single gzipped files.
- The default download dir is hardcoded `/sdcard/Download/ia-get/...` — will change with the
  #75 scoped-storage decision.

## Test coverage snapshot (test/)

- test/: widget_test.dart, models, services, utils
- test/models/: cached_metadata_test.dart
- test/services/: advanced_search_service_test.dart, bandwidth_throttle_test.dart, etag_http_client_test.dart, history_service_test.dart, ia_http_client_test.dart, identifier_verification_service_test.dart, metadata_cache_test.dart, rate_limiter_test.dart, saved_search_service_test.dart.skip, search_history_service_test.dart.skip
- test/utils/: archive_identifier_normalizer_test.dart

No unit tests exist for `DownloadScheduler` or `ResumableDownloadService` — the two files changed
most in this pass. Recommend adding tests with a mocked Dio/DatabaseHelper before the
12-tester production track. CI (`flutter-ci.yml`) runs analyze + test on every push to main,
so this commit is validated by CI.

---

# Round 2 — full pre-launch audit (October 2026)

Scope: the download backends (`BackgroundDownloadService`, `ResumableDownloadService`,
`DownloadScheduler`), the storage/permission layer as wired through the widgets (download
controls, file list, settings, provider), `main.dart` startup, `MainActivity.kt`, and the
Android manifest. Every file above was read end to end.

## Verdict

The architecture holds up. One launch-blocking flaw: the default download directory was
hardcoded to `/storage/emulated/0/Download/ia-get`, which production builds cannot write on
Android 11+ (scoped storage; MANAGE_EXTERNAL_STORAGE is removed from the Play flavor per
#75 Option B) — every download on a production build failed with EACCES before writing a
byte. The default is now the app-scoped external directory, which needs no permission on any
supported Android version. Second big finding: the home-screen bulk pipeline's
pause/cancel/resume called Kotlin methods that were never implemented — the buttons did
nothing, a 500 ms status poller threw on every tick, and no download notification ever fired
from Dart. Both fixed with a pure-Dart implementation.

## Fixed in this commit

| # | Severity | Where | Bug | Fix |
|---|----------|-------|-----|-----|
| 12 | Critical | default download dir | `/storage/emulated/0/Download/ia-get` hardcoded in 5 places; EACCES on Android 11+ production builds | `FileUtils.getDefaultDownloadDirectory()` (app-scoped); settings, provider, controls, file list all resolve through it |
| 13 | Critical | bgdl pause/cancel/resume | Called native `cancelDownload`/`pauseDownload`/`resumeDownload` — never implemented in MainActivity.kt | Pure Dart: CancellationToken threaded into `InternetArchiveApi.downloadFile` |
| 14 | High | bgdl status poller | 500 ms `getDownloadStatuses` poller threw every tick; notifications never fired | Poller removed; throttled 1 s progress + completion/error notifications from the download loop |
| 15 | High | bgdl file layout | Files written flat into the download dir → cross-archive name collisions; the file list (`<dir>/<archiveId>/<file>`) never detected them | Per-archive subfolder `<downloadPath>/<identifier>/<file>` |
| 16 | High | rate limiter | release() decremented, woke a waiter that re-incremented; concurrent acquire() over-admitted (4 of 3) | Permit transfer in release(); queued waiters don't increment |
| 17 | High | resumable service | User pause/cancel recorded as error with retryCount+1 → 5 pauses killed a task; status race with the pause handler | `_userPaused`/`_userCancelled` intents; catch persists paused/cancelled, no retry burn |
| 18 | High | main.dart | Deep-link handler assigned AFTER `initialize()`; cold-start link dispatched inside initialize() was dropped | Handler registered before initialize() |
| 19 | High | MainActivity openFile | `resolveActivity()` null under Android 11+ package visibility → "No app found" always | `startActivity` + `ActivityNotFoundException`; `<queries>` VIEW `*/*` manifest entry |
| 20 | Medium | bgdl completion | Download marked "completed" even when every file failed | completedFiles==0 → error status + error notification |
| 21 | Medium | path handling | Archive-served file names interpolated into paths | `FileUtils.safeJoin` (sanitizes, rejects traversal/absolute) |
| 22 | Medium | MD5 checks | `readAsBytes()` on multi-GB files → OOM | Streamed via `md5.bind(file.openRead())` |
| 23 | Medium | download controls | Blocking permission gate before every download (app-scoped dir needs none) | Best-effort non-blocking request; retry button no longer permission-gated |
| 24 | Medium | file list open | `_openLocalFile` demanded MANAGE_EXTERNAL_STORAGE — ungrantable in production | Gate removed; file list reads the configured download dir |
| 25 | Low | scheduler `_tick` | Network-unsuitable head task starved any-network tasks behind it (break) | Rotate to back of queue (one-full-rotation guard) |
| 26 | Low | scheduler `_startDownload` | Fire-and-forget rethrow → unhandled async exception after onError already reported | `.then((_) {}, onError: ...)` |
| 27 | Low | User-Agent | Three inconsistent identifiers (stale 1.6.0, 'ia-helper', none on Dio) | Unified `InternetArchiveHelper/1.7.1 (+repo)` |

## Flagged — post-1.0

- **Download-location picker (new)** — with the app-scoped default, users cannot target a public
  folder (e.g. `/Download`) on Android 11+ production builds. Post-1.0: SAF/MediaStore picker so
  users can export to public locations without MANAGE_EXTERNAL_STORAGE.
- **Bulk-pipeline pause loses in-flight file progress** — `InternetArchiveApi.downloadFile` has no
  HTTP Range resume, so pausing restarts the in-flight file from byte 0 (completed files are
  kept). Porting Range support into the http streaming path would make pause byte-exact.
- **Two download pipelines** (from Round 1) — consolidate DownloadProvider onto the scheduler.
- **Checksum failures are silent** (from Round 1) — surface a per-file warning state.
- **Cancel does not propagate in DownloadProvider** (from Round 1) — thread the cancellation
  token into `ArchiveService.downloadFile`.

CI (`flutter-ci.yml`) runs analyze + test on every push to main, validating this commit; the
12-tester production track (#76) is the final gate.
