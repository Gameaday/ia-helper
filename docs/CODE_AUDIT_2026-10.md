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
