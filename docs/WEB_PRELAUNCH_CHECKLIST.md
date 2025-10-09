# Web Deployment Pre-Launch Checklist

**Date:** October 8, 2025  
**URL:** https://gameaday.github.io/ia-helper/app/  
**Status:** 🟡 In Progress

---

## ✅ Completed

### Core Functionality
- ✅ **Database Support**: sqflite_common_ffi_web configured with worker files
- ✅ **Platform Detection**: Proper conditional imports for web vs native
- ✅ **Base Href**: Correctly set to `/ia-helper/app/`
- ✅ **Material Design 3**: ~98%+ compliance across all screens
- ✅ **Dark Mode**: Fully functional with theme system
- ✅ **Navigation**: MD3 page transitions standardized

### Build Configuration
- ✅ **GitHub Actions**: Automated deployment workflow
- ✅ **No Tree Shaking**: IconData issues resolved
- ✅ **SQLite Workers**: sqflite_sw.js and sqlite3.wasm included
- ✅ **Code Quality**: 0 warnings, 0 errors from flutter analyze
- ✅ **Tests**: All 129 tests passing

### Documentation
- ✅ **Deployment Guide**: WEBAPP_DEPLOYMENT_CHECKLIST.md
- ✅ **Platform Decisions**: WEB_PLATFORM_DECISIONS.md
- ✅ **WASM Strategy**: Future migration plan documented

---

## ⚠️ Known Limitations (By Design)

### Platform-Specific Features That Won't Work on Web

1. **Video Preview** ❌
   - Uses `dart:io` File operations
   - Requires `path_provider` (not web-compatible for temp files)
   - **Impact**: Video preview widget will crash on web
   - **Solution Needed**: Wrap in platform check or use web-compatible approach

2. **Audio Preview** ⚠️
   - May have similar `dart:io` dependencies
   - **Status**: Needs verification

3. **PDF Preview** ⚠️
   - Uses `pdfx` package (not WASM compatible, but works with JS compilation)
   - **Status**: Should work, but fallback to browser download recommended

4. **Background Downloads** ⚠️
   - Web can't do true background downloads
   - Downloads managed by browser, not app
   - **Impact**: No progress tracking, no pause/resume

5. **File System Access** ⚠️
   - `path_provider` limited on web
   - Downloads go to browser's default folder
   - **Impact**: User can't choose download location

6. **Notifications** ⚠️
   - Requires user permission
   - Don't work when tab closed
   - **Impact**: No background download notifications

7. **Deep Linking** ⚠️
   - `ia://` URLs don't work on web
   - **Solution**: Use URL parameters (e.g., `?item=identifier`)

---

## 🔧 Required Fixes Before Full Launch

### HIGH PRIORITY - Blocking Issues

#### 1. Video Preview Widget Crash
**Status**: ❌ BLOCKING  
**Issue**: Uses `dart:io` File operations that don't work on web

**Fix**: Add platform detection

```dart
// lib/widgets/video_preview_widget.dart
import 'package:flutter/foundation.dart' show kIsWeb;

@override
Widget build(BuildContext context) {
  if (kIsWeb) {
    return _WebVideoFallback(
      videoBytes: widget.videoBytes,
      fileName: widget.fileName,
    );
  }
  // ... existing native video player
}
```

#### 2. Archive Preview Widget
**Status**: ⚠️ NEEDS VERIFICATION  
**Issue**: May use `path_provider` which is problematic on web

**Action**: Test and add platform checks if needed

#### 3. Settings Screen - Download Path
**Status**: ⚠️ NEEDS VERIFICATION  
**Issue**: Download path selection won't work on web

**Fix**: Hide download path setting on web platform

```dart
if (!kIsWeb) {
  // Show download path settings
}
```

### MEDIUM PRIORITY - UX Improvements

#### 4. Download Behavior Communication
**Status**: 📝 NEEDS DOCUMENTATION  
**Issue**: Users expect app-managed downloads, but web uses browser downloads

**Solution**: Add banner/dialog explaining:
- "Downloads are managed by your browser"
- "Check your browser's download folder"
- "Progress tracking not available on web"

#### 5. Viewport Meta Tag
**Status**: ⚠️ MISSING  
**Issue**: Mobile web experience may not be optimal

**Fix**: Add to `web/index.html`:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
```

#### 6. Theme Color Meta Tag
**Status**: ⚠️ MISSING  
**Issue**: Browser UI doesn't match app theme

**Fix**: Add to `web/index.html`:
```html
<meta name="theme-color" content="#6750A4">
<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#D0BCFF">
```

#### 7. Open Graph / Social Sharing Tags
**Status**: ⚠️ MISSING  
**Issue**: Links shared on social media won't have preview

**Fix**: Add to `web/index.html`:
```html
<meta property="og:title" content="Internet Archive Helper">
<meta property="og:description" content="Browse, search, and download from archive.org">
<meta property="og:image" content="https://gameaday.github.io/ia-helper/app/icons/Icon-512.png">
<meta property="og:url" content="https://gameaday.github.io/ia-helper/app/">
<meta name="twitter:card" content="summary_large_image">
```

### LOW PRIORITY - Nice to Have

#### 8. CORS Error Handling
**Status**: ⚠️ UNTESTED  
**Issue**: Internet Archive API might have CORS restrictions

**Test**: Make API calls from web app and verify no CORS errors  
**Solution**: If CORS errors occur, add proper error handling with retry logic

#### 9. Service Worker Optimization
**Status**: ⚠️ DEFAULT CONFIG  
**Issue**: Using default Flutter service worker, no custom caching

**Future Enhancement**: 
- Custom service worker for offline support
- Aggressive caching of static assets
- Background sync for favorites/history

#### 10. Performance Optimization
**Status**: ⚠️ UNTESTED  
**Issue**: Bundle size ~3-4 MB, load time unknown

**Actions**:
- Run Lighthouse audit
- Measure Time to Interactive (target: < 4s)
- Consider code splitting for heavy features

#### 11. 404 Error Page
**Status**: ⚠️ MISSING  
**Issue**: Direct navigation to sub-routes may 404

**Solution**: Configure GitHub Pages SPA handling:
- Copy `index.html` to `404.html` in build output
- Or handle routing client-side

---

## 📋 Testing Checklist

### Browser Compatibility
- [ ] Chrome/Edge (Chromium) - Desktop
- [ ] Firefox - Desktop
- [ ] Safari - Desktop
- [ ] Chrome - Android
- [ ] Safari - iOS
- [ ] Firefox - Android

### Core Features to Test
- [ ] Search Internet Archive
- [ ] View item details
- [ ] Browse collections
- [ ] Add to favorites
- [ ] View search history
- [ ] Theme switching (light/dark)
- [ ] Download files (verify browser download works)
- [ ] Database persistence across sessions
- [ ] Responsive design (320px - 1920px)

### Error Cases to Test
- [ ] Network offline
- [ ] API errors
- [ ] Large dataset handling
- [ ] Low memory/slow connection
- [ ] Video/audio preview on web (should not crash)

### Performance Metrics
- [ ] First Contentful Paint < 2s
- [ ] Time to Interactive < 4s
- [ ] Lighthouse Score > 90
- [ ] No console errors (except source map warnings)

---

## 🚀 Launch Steps

### 1. Fix Blocking Issues
- [ ] Add platform checks to video preview widget
- [ ] Add platform checks to audio preview widget (if needed)
- [ ] Hide web-incompatible settings
- [ ] Test all preview types on web

### 2. Enhance HTML Metadata
- [ ] Add viewport meta tag
- [ ] Add theme-color meta tags
- [ ] Add Open Graph tags
- [ ] Add Twitter Card tags

### 3. Enable GitHub Pages
- [ ] Go to repository settings
- [ ] Pages section → Source: "GitHub Actions"
- [ ] Wait for deployment
- [ ] Verify site loads

### 4. Test Production Deployment
- [ ] Visit https://gameaday.github.io/ia-helper/app/
- [ ] Open DevTools console (check for errors)
- [ ] Test search functionality
- [ ] Test database operations (favorites, history)
- [ ] Test downloads (verify browser manages them)
- [ ] Test on mobile browser
- [ ] Run Lighthouse audit

### 5. Document Known Issues
- [ ] Update README with web app limitations
- [ ] Add "Web vs Mobile" feature comparison
- [ ] Link to web app in README
- [ ] Update PRIVACY_POLICY.md if needed

---

## 🐛 Known Web-Specific Issues

### Source Map Warnings (Non-Critical)
```
Source map error: request failed with status 404
Resource URL: flutter_bootstrap.js
Source Map URL: flutter.js.map
```
**Impact**: None - only affects debugging  
**Solution**: Ignore or generate source maps in release build (adds size)

### WASM Warnings (Non-Critical)
```
Wasm dry run findings: pdfx package incompatibilities
```
**Impact**: None - we use JS compilation  
**Solution**: Already documented in WEB_PLATFORM_DECISIONS.md

---

## 📊 Success Criteria

The web app is production-ready when:

1. ✅ No blocking errors in browser console
2. ⚠️ All features work or gracefully degrade on web
3. ⚠️ Database persistence works across sessions
4. ⚠️ Downloads trigger browser download UI
5. ⚠️ Responsive on mobile, tablet, desktop
6. ⚠️ Lighthouse score > 90
7. ⚠️ GitHub Pages enabled and serving content
8. ⚠️ CORS issues resolved or handled gracefully
9. ⚠️ Preview features don't crash (platform checks in place)
10. ⚠️ Documentation updated with web limitations

---

## 🔗 Resources

- **Web App URL**: https://gameaday.github.io/ia-helper/app/
- **Repository**: https://github.com/Gameaday/ia-helper
- **Actions**: https://github.com/Gameaday/ia-helper/actions
- **Pages Settings**: https://github.com/Gameaday/ia-helper/settings/pages

**Related Documentation**:
- `docs/WEBAPP_DEPLOYMENT_CHECKLIST.md` - General deployment guide
- `docs/WEB_PLATFORM_DECISIONS.md` - Technical decisions
- `docs/FIXING_WEB_APP_DEPLOYMENT.md` - Troubleshooting

---

**Last Updated**: October 8, 2025  
**Next Review**: After first deployment test
