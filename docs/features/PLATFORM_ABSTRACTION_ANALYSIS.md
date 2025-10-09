# Platform Abstraction Opportunities Analysis

**Date:** October 9, 2025  
**Goal:** Identify all platform-specific code and create abstraction layers  
**Philosophy:** Mobile-first, web adapts automatically

---

## Current Platform-Specific Code Inventory

### Summary Statistics
- **Total `kIsWeb` checks in codebase:** ~77 occurrences
- **Services with checks:** 5 files
- **Screens with checks:** 3 files
- **Utils with checks:** 1 file
- **Database with checks:** 1 file

---

## Category 1: File System Operations ✅ ABSTRACTED

**Status:** ✅ Complete - `StorageAdapter` created

**Files:**
- `thumbnail_cache_service.dart` - 11 checks
- `database_helper.dart` - 1 check

**Solution:** `lib/core/platform/storage_adapter.dart`
- Provides virtual directories on web
- Real file system on native
- Zero business logic changes needed

---

## Category 2: HTTP/Network Operations 🔄 CAN ABSTRACT

### 2.1 User-Agent Headers

**Current code:**
```dart
// ia_http_client.dart line 432
if (!kIsWeb) 'User-Agent': userAgent,

// ia_http_client.dart line 487
if (kIsWeb) {
  return 'Flutter/$_kFlutterVersion (Web)';
}
```

**Why it exists:** Browsers automatically set User-Agent, manual setting causes errors on web

**Abstraction opportunity:** ✅ YES
```dart
// lib/core/platform/http_adapter.dart
class HttpHeadersAdapter {
  Map<String, String> getPlatformHeaders() {
    if (kIsWeb) {
      // Web: Browser handles User-Agent automatically
      return {};
    }
    // Native: Include custom User-Agent
    return {
      'User-Agent': 'IA-Helper/1.0 Flutter/3.35.5 Dart/3.9.2',
    };
  }
}
```

**Benefits:**
- Remove 2 `kIsWeb` checks from `ia_http_client.dart`
- Centralize HTTP header logic
- Easy to add more platform-specific headers

---

### 2.2 CORS Restrictions

**Current code:**
```dart
// thumbnail_url_service.dart line 57
if (!kIsWeb) return false;
```

**Why it exists:** CORS only affects web browsers, not native apps

**Abstraction opportunity:** ✅ ALREADY IN StorageAdapter
```dart
abstract class StorageAdapter {
  bool get hasCorsRestrictions; // true on web, false on native
}
```

**Status:** ✅ Already handled by existing abstractions

---

## Category 3: Native Platform Features 🎯 SHOULD ABSTRACT

### 3.1 Notification Service

**Current code:**
```dart
// notification_service.dart line 23
if (kIsWeb) {
  _isInitialized = true; // Mark as initialized
  return; // Notifications not supported on web
}
```

**Why it exists:** MethodChannel only works on native platforms

**Abstraction opportunity:** ✅ YES - HIGH PRIORITY
```dart
// lib/core/platform/notification_adapter.dart
abstract class NotificationAdapter {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> showProgress(String id, String title, int progress);
  Future<void> showCompletion(String id, String title);
  Future<void> cancelNotification(int id);
}

// Native implementation
class NativeNotificationAdapter implements NotificationAdapter {
  final MethodChannel _channel = const MethodChannel('...');
  
  @override
  Future<void> initialize() async {
    await _channel.invokeMethod('initialize', {...});
  }
  // ... real implementations
}

// Web implementation
class WebNotificationAdapter implements NotificationAdapter {
  @override
  Future<void> initialize() async {
    // No-op on web
  }
  
  @override
  Future<bool> requestPermissions() async => false;
  
  @override
  Future<void> showProgress(String id, String title, int progress) async {
    // Could use browser notifications API if desired
    // Or just no-op
  }
  // ... all no-ops
}

// Factory
NotificationAdapter getNotificationAdapter() {
  if (kIsWeb) return WebNotificationAdapter();
  return NativeNotificationAdapter();
}
```

**Benefits:**
- Remove 1 `kIsWeb` check from `notification_service.dart`
- Clean separation of concerns
- Future: Could implement browser notifications API
- Easier to test (mock adapter)

---

### 3.2 File Preview Screen

**Current code:**
```dart
// file_preview_screen.dart line 145
if (kIsWeb) {
  return Scaffold(
    // ... "Preview not available on web" UI
  );
}
```

**Why it exists:** Native file preview uses platform viewers, not available on web

**Abstraction opportunity:** ✅ YES - MEDIUM PRIORITY
```dart
// lib/core/platform/file_preview_adapter.dart
abstract class FilePreviewAdapter {
  bool canPreview(String format);
  Widget buildPreview(ArchiveFile file, {required BuildContext context});
}

// Native implementation
class NativeFilePreviewAdapter implements FilePreviewAdapter {
  @override
  bool canPreview(String format) {
    return ['pdf', 'txt', 'jpg', 'png', 'mp3', 'mp4'].contains(format);
  }
  
  @override
  Widget buildPreview(ArchiveFile file, {required BuildContext context}) {
    // Return native PDF viewer, image viewer, etc.
    return _buildNativePreview(file);
  }
}

// Web implementation
class WebFilePreviewAdapter implements FilePreviewAdapter {
  @override
  bool canPreview(String format) => false; // No preview on web
  
  @override
  Widget buildPreview(ArchiveFile file, {required BuildContext context}) {
    // Return "download to view" message
    return _buildDownloadPrompt(file);
  }
}
```

**Benefits:**
- Remove large `kIsWeb` block from screen code
- Cleaner screen logic
- Future: Could add iframe previews for some formats

---

### 3.3 Settings Screen - Download Location

**Current code:**
```dart
// settings_screen.dart line 162
if (!kIsWeb)
  ListTile(
    title: Text('Download Location'),
    // ... download location picker
  ),
```

**Why it exists:** Web uses browser downloads, no custom location selection

**Abstraction opportunity:** ⚠️ MAYBE - LOW PRIORITY
```dart
// lib/core/platform/download_adapter.dart
abstract class DownloadAdapter {
  bool get supportsCustomLocation;
  Future<String?> pickDownloadLocation();
  Future<void> downloadFile(String url, String filename);
}
```

**Benefits:** Minor - only 1 check, UI-level logic is acceptable here

**Recommendation:** Keep `kIsWeb` check in UI - it's a UI decision, not business logic

---

### 3.4 API Settings Screen - Advanced Settings

**Current code:**
```dart
// api_settings_screen.dart line 81
if (!kIsWeb) ...[
  SectionHeader(title: 'Advanced'),
  // ... advanced settings
],
```

**Why it exists:** Some settings don't apply to web

**Abstraction opportunity:** ⚠️ MAYBE - LOW PRIORITY

**Recommendation:** Keep `kIsWeb` check in UI - acceptable for UI-level feature flags

---

## Category 4: Database Operations ⚠️ SPECIAL CASE

### 4.1 Web Database Factory

**Current code:**
```dart
// database_helper.dart line 45
if (kIsWeb && webDatabaseFactory != null) {
  return webDatabaseFactory!.openDatabase(path);
}
```

**Why it exists:** Web uses different SQLite implementation (sql.js)

**Abstraction opportunity:** ⚠️ COMPLEX
```dart
// lib/core/platform/database_adapter.dart
abstract class DatabaseAdapter {
  Future<Database> openDatabase(String path);
}
```

**Recommendation:** ✅ Worth abstracting, but requires careful testing

---

## Priority Ranking for Abstraction

### 🔥 HIGH PRIORITY (Do Now)
1. **NotificationAdapter** - Clean separation, 1 check removed, testable
2. **HttpHeadersAdapter** - Centralize HTTP logic, 2 checks removed
3. **FilePreviewAdapter** - Large code block, improves screen readability

### 🎯 MEDIUM PRIORITY (Do Next)
4. **ThumbnailCacheService migration** - Use StorageAdapter (11 checks removed!)
5. **DatabaseAdapter** - Cleaner database handling

### 🔵 LOW PRIORITY (Optional)
6. **DownloadAdapter** - Minimal benefit, UI-level checks are acceptable
7. **Settings UI checks** - Keep as-is, UI feature flags are fine

---

## Proposed New Adapters

### 1. NotificationAdapter (HIGH)
**File:** `lib/core/platform/notification_adapter.dart`  
**Removes:** 1 check from `notification_service.dart`  
**Benefit:** Clean API, testable, future-proof (could add browser notifications)

### 2. HttpHeadersAdapter (HIGH)
**File:** `lib/core/platform/http_headers_adapter.dart`  
**Removes:** 2 checks from `ia_http_client.dart`  
**Benefit:** Centralized HTTP logic, easier to maintain

### 3. FilePreviewAdapter (HIGH)
**File:** `lib/core/platform/file_preview_adapter.dart`  
**Removes:** Large block from `file_preview_screen.dart`  
**Benefit:** Cleaner screen code, separation of concerns

### 4. DatabaseAdapter (MEDIUM)
**File:** `lib/core/platform/database_adapter.dart`  
**Removes:** 1 check from `database_helper.dart`  
**Benefit:** Platform-agnostic database API

---

## Expected Outcomes After Full Abstraction

### Code Quality Metrics

| Category | Before | After | Improvement |
|----------|--------|-------|-------------|
| Services with `kIsWeb` | 5 | 0 | **100%** ✅ |
| Screens with `kIsWeb` | 3 | 2* | **33%** ✅ |
| Total business logic checks | ~20 | 0 | **100%** ✅ |
| Platform adapters | 1 | 5 | Clean architecture ✅ |

\* *Remaining checks are acceptable UI-level feature flags*

### Architecture Benefits

**Before:**
```dart
// Scattered platform checks everywhere
if (kIsWeb) { /* web code */ } else { /* native code */ }
```

**After:**
```dart
// Clean adapter pattern everywhere
final adapter = PlatformAdapter(); // Auto-detects
await adapter.doSomething(); // Works on all platforms
```

---

## Implementation Plan

### Phase 1: Core Adapters (1-2 hours)
1. ✅ `StorageAdapter` - Complete
2. ✅ `ThumbnailUrlService` - Complete
3. ⏳ `NotificationAdapter` - To do
4. ⏳ `HttpHeadersAdapter` - To do

### Phase 2: Service Migration (1-2 hours)
1. Update `thumbnail_cache_service.dart` to use `StorageAdapter`
2. Update `notification_service.dart` to use `NotificationAdapter`
3. Update `ia_http_client.dart` to use `HttpHeadersAdapter`

### Phase 3: UI Adapters (1 hour)
1. `FilePreviewAdapter` - Clean up preview screen
2. Update `file_preview_screen.dart` to use adapter

### Phase 4: Optional (30 min)
1. `DatabaseAdapter` - If time permits
2. Keep UI-level `kIsWeb` checks as acceptable

---

## Decision Matrix: Should We Abstract?

### ✅ Abstract when:
- Logic is in **business layer** (services, models)
- Check appears in **multiple places**
- Platform difference is **complex** (like notifications)
- Future **extensibility** needed (browser notifications)
- Improves **testability**

### ❌ Keep `kIsWeb` when:
- Logic is in **UI layer** (showing/hiding widgets)
- Check appears **only once**
- Platform difference is **simple** (like hiding a button)
- UI-specific **feature flags**

---

## Summary

### Recommended Abstractions:
1. ✅ **StorageAdapter** (done)
2. ✅ **ThumbnailUrlService** (done)
3. 🎯 **NotificationAdapter** (high priority)
4. 🎯 **HttpHeadersAdapter** (high priority)
5. 🎯 **FilePreviewAdapter** (high priority)
6. ⚠️ **DatabaseAdapter** (medium priority)

### Keep as `kIsWeb`:
- Settings UI feature flags
- Download location picker visibility
- API settings advanced section

### Expected Result:
- **~95% reduction** in business logic platform checks
- **Clean architecture** with adapter pattern
- **Mobile-first** philosophy maintained
- **Easy testing** with mockable adapters
- **Future-proof** for new platforms

---

**Next Steps:**
1. Create remaining high-priority adapters
2. Migrate services to use adapters
3. Remove all `kIsWeb` checks from business logic
4. Test thoroughly on both platforms
5. Document adapter pattern for future features

---

**Total Estimated Effort:** 3-4 hours  
**Expected `kIsWeb` Reduction:** 95% in business logic  
**Architecture Quality:** Significantly improved ✅
