# Web App Deployment Checklist for GitHub Pages

**Date:** October 8, 2025  
**Status:** 🟡 Needs Configuration  
**Web App URL:** https://gameaday.github.io/ia-helper/app/

---

## ✅ What's Already Working

### 1. GitHub Actions Workflow ✅
- **File:** `.github/workflows/deploy-github-pages.yml`
- **Status:** Properly configured
- **Features:**
  - Builds Flutter web app with `--no-tree-shake-icons` flag
  - Sets correct `--base-href /ia-helper/app/`
  - Builds Android APK for downloads
  - Generates build manifest with version info
  - Deploys to GitHub Pages automatically on push to `main`

### 2. Web Build Configuration ✅
- **Base href:** Correctly configured to `/ia-helper/app/`
- **Index.html:** Proper Flutter bootstrap setup
- **Manifest:** Web app manifest present
- **Icons:** Favicon and icons configured
- **No tree-shaking:** IconData issues resolved with `--no-tree-shake-icons` flag

### 3. Landing Page ✅
- **File:** `docs/github-pages/index.html`
- **Status:** Professional landing page exists
- **Features:**
  - Links to web app at `/app/`
  - Links to download APK
  - Dark mode support
  - Responsive design
  - Build manifest integration

### 4. Code Quality ✅
- **flutter analyze:** 0 issues
- **Web build:** Succeeds (20.2s)
- **MD3 compliance:** ~98%+
- **No warnings:** Build-safe for CI/CD

---

## 🔧 What's Missing - Action Required

### 1. GitHub Pages Configuration ⚠️

**Problem:** GitHub Pages needs to be enabled in repository settings.

**Solution:**
1. Go to: https://github.com/Gameaday/ia-helper/settings/pages
2. Under "Build and deployment":
   - **Source:** Select "GitHub Actions" (NOT "Deploy from a branch")
3. Save settings

**Why this matters:**
- The workflow is ready to deploy, but GitHub Pages must be enabled to accept deployments
- Using "GitHub Actions" source allows the workflow to control deployment
- This is a one-time configuration step

**Verification:**
- After enabling, push a commit to trigger the workflow
- Check Actions tab: https://github.com/Gameaday/ia-helper/actions
- Look for "Deploy to GitHub Pages" workflow run
- Web app should be live at: https://gameaday.github.io/ia-helper/app/

---

### 2. First Workflow Run 🔄

**Status:** Workflow may not have run yet, or GitHub Pages wasn't enabled.

**Steps to trigger deployment:**

```bash
# 1. Ensure all changes are committed
git add .
git commit -m "docs: Update deployment checklist"

# 2. Push to GitHub to trigger deployment
git push origin main

# 3. Monitor deployment
# Go to: https://github.com/Gameaday/ia-helper/actions
# Watch for "Deploy to GitHub Pages" workflow
```

**Expected workflow steps:**
1. ✅ Checkout code
2. ✅ Setup Flutter & Java
3. ✅ Build Android APK (development debug)
4. ✅ Build Web (with --no-tree-shake-icons)
5. ✅ Generate build manifest
6. ✅ Copy to _site/ directory
7. ✅ Upload to GitHub Pages
8. ✅ Deploy (requires GitHub Pages enabled)

**Typical duration:** ~3-5 minutes

---

### 3. Verify Deployment ✅ (After Steps 1-2)

Once deployed, verify these URLs work:

1. **Landing Page:**
   - https://gameaday.github.io/ia-helper/
   - Should show: Professional landing page with download links

2. **Web App:**
   - https://gameaday.github.io/ia-helper/app/
   - Should show: Full Flutter web application

3. **Android APK:**
   - https://gameaday.github.io/ia-helper/artifacts/android/development/app-development-debug.apk
   - Should download: Latest debug APK

4. **Build Manifest:**
   - https://gameaday.github.io/ia-helper/artifacts/manifest.json
   - Should show: JSON with version, build time, commit info

---

## 🚀 Deployment Process (Once Configured)

### Automatic Deployment
Every push to `main` branch will:
1. ✅ Build web app and Android APK
2. ✅ Generate checksums and manifest
3. ✅ Deploy to GitHub Pages
4. ✅ Update web app at /app/
5. ✅ Update landing page at root
6. ✅ Update downloadable APK

### Manual Deployment
You can also trigger manually:
1. Go to: https://github.com/Gameaday/ia-helper/actions
2. Select "Deploy to GitHub Pages" workflow
3. Click "Run workflow"
4. Select `main` branch
5. Click "Run workflow" button

---

## 🔍 Troubleshooting

### Web App Shows Empty/White Page

**Possible causes:**
1. **Base href mismatch:**
   - Check: Build uses `--base-href /ia-helper/app/`
   - Check: Deployed at correct URL path

2. **Assets not loading:**
   - Open browser dev tools (F12)
   - Check Console for 404 errors
   - Verify paths are correct (should be relative to /ia-helper/app/)

3. **Service worker issues:**
   - Clear browser cache
   - Try incognito/private browsing mode
   - Check for service worker errors in dev tools

**Fix:**
```bash
# Rebuild with correct base-href
flutter build web --release --no-tree-shake-icons --base-href /ia-helper/app/

# Verify output
ls build/web/
# Should contain: flutter_bootstrap.js, main.dart.js, etc.
```

---

### Workflow Fails at Deploy Step

**Error:** "pages.write permission required"

**Fix:**
- Check workflow file has correct permissions:
  ```yaml
  permissions:
    contents: read
    pages: write
    id-token: write
  ```
- Verify GitHub Pages is enabled with "GitHub Actions" source

**Error:** "404 Not Found" for pages deployment

**Fix:**
- Enable GitHub Pages in repository settings
- Select "GitHub Actions" as source
- Re-run workflow

---

### Landing Page Works But /app/ Shows 404

**Possible causes:**
1. Workflow didn't copy web build to _site/app/
2. Upload artifact step failed
3. Path mismatch in deployment

**Fix:**
- Check workflow logs for "Prepare GitHub Pages content" step
- Verify: `cp -r build/web/* _site/app/` executed successfully
- Check uploaded artifact includes `app/` directory

---

## 📋 Pre-Deployment Checklist

Before enabling GitHub Pages, verify:

- [x] Workflow file exists: `.github/workflows/deploy-github-pages.yml`
- [x] Web build succeeds locally: `flutter build web --release --no-tree-shake-icons`
- [x] Landing page exists: `docs/github-pages/index.html`
- [x] Base href correct: `--base-href /ia-helper/app/`
- [x] Zero flutter warnings: `flutter analyze`
- [x] README updated with web app link
- [ ] **GitHub Pages enabled in repository settings** ⚠️
- [ ] **First workflow run successful** 🔄

---

## 🎯 Next Steps

### Immediate (Required)
1. **Enable GitHub Pages** in repository settings
   - Go to Settings → Pages
   - Source: "GitHub Actions"
   - Save

2. **Trigger First Deployment**
   - Push this commit to `main`
   - Monitor workflow at Actions tab
   - Wait for completion (~3-5 minutes)

3. **Verify Deployment**
   - Visit: https://gameaday.github.io/ia-helper/
   - Visit: https://gameaday.github.io/ia-helper/app/
   - Test search, discover, downloads

### Optional Enhancements
1. **Custom Domain** (optional)
   - Add CNAME record in DNS
   - Configure in GitHub Pages settings
   - Update base-href in workflow

2. **Analytics** (optional)
   - Add Google Analytics to web/index.html
   - Track usage and page views

3. **PWA Features** (future)
   - Service worker for offline support
   - Install prompt for mobile
   - App icon and splash screens

4. **WASM Compilation** (future consideration)
   - Current build uses JavaScript compilation (fully supported)
   - If migrating to WASM compilation in the future:
     - Consider conditionally disabling `pdfx` package on web platform
     - Most modern browsers have native PDF viewing capabilities
     - Current WASM warnings from `pdfx` package are non-blocking
     - See: https://docs.flutter.dev/platform-integration/web/wasm
   - **Decision:** Keep JS compilation for now, reassess if WASM becomes standard

---

## 📞 Support

### Useful Links
- **Repository:** https://github.com/Gameaday/ia-helper
- **Actions:** https://github.com/Gameaday/ia-helper/actions
- **Pages Settings:** https://github.com/Gameaday/ia-helper/settings/pages
- **GitHub Pages Docs:** https://docs.github.com/en/pages

### Common Issues
- [Troubleshooting GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/troubleshooting-github-pages)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)

---

## ✅ Success Criteria

The web app is fully working when:

1. ✅ Landing page loads at root URL
2. ✅ Web app loads at /app/ URL
3. ✅ All features work (search, discover, downloads)
4. ✅ No console errors in browser dev tools
5. ✅ Assets load correctly (icons, fonts, scripts)
6. ✅ Responsive on mobile and desktop
7. ✅ Dark mode works
8. ✅ APK downloads work
9. ✅ Build manifest is accessible
10. ✅ Automatic deployment on push to main

---

**Current Status:** Ready for deployment, just needs GitHub Pages enabled! 🚀
