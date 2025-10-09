# Web Platform Implementation Decisions

**Last Updated:** October 8, 2025  
**Status:** Active Development

---

## Overview

This document tracks architectural decisions and trade-offs specific to the web platform implementation of ia-helper.

---

## JavaScript vs WASM Compilation

### Current Decision: JavaScript Compilation ✅

**Date:** October 8, 2025  
**Status:** Active

We use standard JavaScript compilation for the Flutter web build:
```bash
flutter build web --release --no-tree-shake-icons --base-href="/ia-helper/app/"
```

### Rationale

1. **Full Flutter Support:** JavaScript compilation is production-ready and fully supported
2. **Package Compatibility:** All dependencies work correctly with JS compilation
3. **No Breaking Warnings:** Build succeeds without critical issues
4. **Performance:** Adequate for our use case (archive browsing, search, downloads)

### WASM Warnings (Non-Critical)

During build, the following WASM compatibility warnings appear from the `pdfx` package:

```
Wasm dry run findings:
Found incompatibilities with WebAssembly.

package:pdfx/src/renderer/web/pdfjs.dart 136:12 - Initializers for parameters are ignored on static interop external functions
package:pdfx/src/renderer/web/pdfjs.dart 137:12 - Initializers for parameters are ignored on static interop external functions
package:pdfx/src/renderer/web/pdfjs.dart 138:10 - Initializers for parameters are ignored on static interop external functions
package:pdfx/src/renderer/web/pdfjs.dart 205:12 - Initializers for parameters are ignored on static interop external functions
package:pdfx/src/renderer/web/pdfjs.dart 206:10 - Initializers for parameters are ignored on static interop external functions
package:pdfx/src/renderer/web/pdfjs.dart 207:10 - Initializers for parameters are ignored on static interop external functions
```

**Impact:** None - these are informational warnings about future WASM compatibility.

---

## Future WASM Migration Plan

### When to Consider WASM

Migrate to WASM compilation if/when:
- WASM becomes the recommended default for Flutter web
- Significant performance improvements are needed
- WASM compilation is required for specific features

### Migration Strategy for pdfx

**Recommendation:** Conditionally disable `pdfx` on web platform

**Rationale:**
- Modern browsers have native PDF viewing capabilities
- Users can download PDFs and view in browser's built-in viewer
- Eliminates WASM compatibility warnings
- Reduces web bundle size

**Implementation Pattern:**

```dart
// lib/widgets/pdf_preview_widget.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class PdfPreviewWidget extends StatefulWidget {
  // ...
  
  @override
  Widget build(BuildContext context) {
    // On web, show download button instead of inline preview
    if (kIsWeb) {
      return _WebPdfFallback(
        pdfBytes: widget.pdfBytes,
        fileName: widget.fileName,
      );
    }
    
    // On mobile/desktop, use pdfx for inline preview
    return _NativePdfPreview(
      pdfBytes: widget.pdfBytes,
      fileName: widget.fileName,
    );
  }
}

class _WebPdfFallback extends StatelessWidget {
  // Shows "Download PDF" button that triggers browser download
  // Browser will use native PDF viewer
}
```

**Alternative:** Replace `pdfx` with WASM-compatible PDF package if one becomes available.

---

## Database: SQLite on Web

### Implementation: sqflite_common_ffi_web ✅

**Date:** October 8, 2025  
**Status:** Implemented

**Challenge:** SQLite doesn't work natively in web browsers.

**Solution:** Use IndexedDB-based SQLite emulation via `sqflite_common_ffi_web`

**Implementation:**
```dart
// lib/database/database_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' 
    if (dart.library.io) 'package:sqflite/sqflite.dart';

Future<Database> _initDatabase() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  return await openDatabase(
    // ... rest of initialization
  );
}
```

**Dependencies:**
```yaml
dependencies:
  sqflite: ^2.4.1
  sqflite_common_ffi_web: ^0.4.5+1  # Web-compatible SQLite using IndexedDB
```

**Trade-offs:**
- ✅ Works seamlessly across web and mobile
- ✅ Same database API on all platforms
- ⚠️ IndexedDB has storage limits (typically 50MB-1GB depending on browser)
- ⚠️ Performance not as good as native SQLite, but acceptable for our use case

---

## Platform-Specific Features

### Features Available on All Platforms

- ✅ Search and browse Internet Archive
- ✅ View item details and metadata
- ✅ Favorites and collections
- ✅ Search history
- ✅ Settings and preferences
- ✅ Dark mode / theming

### Features Limited on Web

1. **Background Downloads**
   - **Mobile/Desktop:** Full background download support with notifications
   - **Web:** Downloads initiated but managed by browser (no background tasks)
   - **Reason:** Web browsers don't support persistent background tasks

2. **File System Access**
   - **Mobile/Desktop:** Save to user-selected directories
   - **Web:** Downloads to browser's default download folder
   - **Reason:** Web File System API limitations

3. **Offline Support** (Future)
   - **Mobile/Desktop:** Full offline mode with cached content
   - **Web:** Limited offline support via service workers (PWA)
   - **Status:** Not yet implemented on any platform

### Platform Detection Pattern

```dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

if (kIsWeb) {
  // Web-specific implementation
} else if (defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS) {
  // Mobile-specific implementation
} else {
  // Desktop-specific implementation
}
```

---

## Performance Considerations

### Web Build Size

Current build output:
- **main.dart.js:** ~2-3 MB (gzipped)
- **Assets:** ~500 KB
- **Total:** ~3-4 MB initial load

**Optimization Opportunities:**
1. Code splitting (future Flutter feature)
2. Lazy loading of heavy dependencies
3. Asset optimization
4. Service worker caching (PWA)

### Load Time

Target metrics:
- **First Paint:** < 2 seconds
- **Time to Interactive:** < 4 seconds
- **Search Response:** < 1 second

**Current Status:** Acceptable performance on modern browsers with broadband.

---

## Testing Strategy

### Web-Specific Tests

1. **Browser Compatibility**
   - Chrome/Edge (Chromium)
   - Firefox
   - Safari
   - Mobile browsers

2. **Database Operations**
   - Verify IndexedDB storage works
   - Test cache persistence across sessions
   - Validate storage quota handling

3. **Download Behavior**
   - Test file downloads trigger correctly
   - Verify browser download UI appears
   - Check download progress (browser-managed)

4. **Responsive Design**
   - Desktop (1920x1080 and up)
   - Tablet (768px - 1024px)
   - Mobile (360px - 767px)

---

## Known Limitations

### 1. No System Notifications
- Web browsers require user permission for notifications
- Notifications don't work when browser tab is closed
- **Mitigation:** In-app notifications only

### 2. Storage Quotas
- IndexedDB typically limited to 50MB-1GB
- Varies by browser and available disk space
- **Mitigation:** Cache management and cleanup strategies

### 3. No Deep Linking (Yet)
- Web app doesn't handle `ia://` URLs
- **Status:** Not implemented
- **Future:** Use URL parameters (`?item=identifier`)

### 4. PDF Preview on WASM
- Current `pdfx` package not WASM-compatible
- **Current:** Works fine with JS compilation
- **Future:** Use browser native PDF viewer on web platform

---

## Decision Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2025-10-08 | Use JavaScript compilation | Full support, no critical issues | Active |
| 2025-10-08 | Keep pdfx with JS compilation | Works fine, WASM warnings non-blocking | Active |
| 2025-10-08 | Use sqflite_common_ffi_web | Enables SQLite on web via IndexedDB | Active |
| 2025-10-08 | Future: Disable pdfx on web if migrating to WASM | Browsers have native PDF viewers | Planned |

---

## References

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Flutter WASM Documentation](https://docs.flutter.dev/platform-integration/web/wasm)
- [sqflite_common_ffi_web Package](https://pub.dev/packages/sqflite_common_ffi_web)
- [IndexedDB API](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)
- [Web File System API](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API)

---

**Maintained by:** Development Team  
**Next Review:** When Flutter WASM becomes production-ready
