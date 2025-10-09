# Fixing the Flutter Web App on GitHub Pages

**Problem:** https://gameaday.github.io/ia-helper/app/ is not working  
**Status:** 🔍 Diagnosis needed  
**Date:** October 8, 2025

---

## ✅ Local Build is Now Fixed

The web app now builds correctly with proper base-href:

```bash
flutter build web --release --no-tree-shake-icons --base-href="/ia-helper/app/"
```

**Verification:**
```bash
Get-Content build\web\index.html | Select-String -Pattern "base href"
# Result: <base href="/ia-helper/app/">  ✅ Correct!
```

---

## 🔍 Diagnosing the Deployed Site Issue

### Step 1: Check if GitHub Pages is Enabled

**Most Likely Cause:** GitHub Pages is not enabled in repository settings.

**How to check:**
1. Go to: https://github.com/Gameaday/ia-helper/settings/pages
2. Look under "Build and deployment"
3. **Required setting:** Source must be set to **"GitHub Actions"**

**If it says "None" or "Deploy from a branch":**
- This is the problem! The workflow can't deploy without this setting.
- **Fix:** Change source to "GitHub Actions" and save

---

### Step 2: Check if Workflow Has Run

**Check workflow runs:**
1. Go to: https://github.com/Gameaday/ia-helper/actions
2. Look for "Deploy to GitHub Pages" workflow
3. Check the status of recent runs

**Expected workflow status:**
- ✅ **All green checks:** Deployment successful, GitHub Pages setting issue
- ❌ **Red X:** Workflow failed, need to check logs
- ⚪ **No runs:** Workflow hasn't been triggered yet

**If no workflow runs:**
```bash
# Push a commit to trigger deployment
git add .
git commit -m "fix: Rebuild web app with correct base-href"
git push origin main
```

---

### Step 3: Check Workflow Logs (If Failed)

If the workflow has red X's:

1. Click on the failed workflow run
2. Click on "build-and-deploy" job
3. Look for errors in these steps:
   - "Build Web (no icon tree-shaking)" - Should succeed
   - "Upload to GitHub Pages" - Needs GitHub Pages enabled
   - "Deploy to GitHub Pages" - Most likely to fail if Pages not enabled

**Common errors:**

**Error:** "pages.write permission required"
- **Cause:** GitHub Pages not enabled
- **Fix:** Enable GitHub Pages with "GitHub Actions" source

**Error:** "404 Not Found"
- **Cause:** Pages deployment endpoint not available
- **Fix:** Enable GitHub Pages in settings

---

## 🚀 Complete Fix Guide

### Option A: Quick Test (Already Have Local Build)

Since we just rebuilt the web app correctly, you can test it locally:

```bash
# Serve the web app locally
cd build\web
python -m http.server 8000

# Or use Flutter's serve
flutter run -d web-server --web-port=8000
```

**Test URL:** http://localhost:8000  
(Note: It will look for assets at /ia-helper/app/ which won't work locally, but proves the build is correct)

---

### Option B: Deploy to GitHub Pages (Recommended)

**Step 1: Enable GitHub Pages**
1. Go to https://github.com/Gameaday/ia-helper/settings/pages
2. Under "Build and deployment":
   - Source: **"GitHub Actions"** (not "Deploy from a branch")
3. Click "Save"

**Step 2: Trigger Deployment**
```bash
# Commit the newly built web app
git add build/web/
git commit -m "fix: Add correctly built web app with base-href"
git push origin main
```

**Step 3: Wait for Deployment**
- Go to: https://github.com/Gameaday/ia-helper/actions
- Watch "Deploy to GitHub Pages" workflow
- Wait ~3-5 minutes for completion

**Step 4: Verify Deployment**
- Visit: https://gameaday.github.io/ia-helper/app/
- Should load the full Flutter web application
- Check browser console (F12) for any errors

---

## 🐛 Still Not Working? Advanced Troubleshooting

### Issue: Web App Shows White/Blank Page

**Check 1: Browser Console**
```javascript
// Open browser dev tools (F12)
// Look for errors like:
- "Failed to load resource: 404"
- "main.dart.js:1 Failed to load"
- "flutter_bootstrap.js 404"
```

**If you see 404 errors for assets:**
- Base-href is wrong or assets not deployed
- Check: View page source, verify `<base href="/ia-helper/app/">`

**Check 2: Network Tab**
```javascript
// In dev tools, go to Network tab
// Reload page
// Look at which files are loading:
✅ Should load from: /ia-helper/app/flutter_bootstrap.js
❌ Don't want: /flutter_bootstrap.js (wrong base path)
```

---

### Issue: GitHub Actions Workflow Not Visible

**Possible causes:**
1. Workflow file not in correct location
2. YAML syntax error
3. Branch protection rules

**Verification:**
```bash
# Check workflow file exists
Test-Path .github\workflows\deploy-github-pages.yml
# Should return: True

# Check YAML syntax
Get-Content .github\workflows\deploy-github-pages.yml | Select-String -Pattern "on:"
# Should show: on: push: branches: [ main ]
```

---

### Issue: Workflow Runs But Deployment Step Fails

**Error message:** "Error: No uploaded artifact was found!"

**Cause:** Upload step failed or artifact expired

**Fix:**
1. Check "Upload to GitHub Pages" step succeeded
2. Verify `_site` directory was created correctly
3. Re-run workflow

---

## 📋 Pre-Deployment Checklist

Before enabling GitHub Pages, verify:

- [x] Web app builds successfully locally
- [x] Base-href is set to `/ia-helper/app/` in built index.html
- [x] All assets present in `build/web/` directory
- [x] Workflow file at `.github/workflows/deploy-github-pages.yml`
- [x] Workflow has correct build command with quotes
- [ ] **GitHub Pages enabled in repository settings** ⚠️
- [ ] **Workflow has run successfully** 🔄
- [ ] **Web app accessible at URL** 🎯

---

## 🔧 Workflow Command Fix (For Reference)

The GitHub Actions workflow should use this command (Linux bash):

```yaml
- name: Build Web (no icon tree-shaking)
  run: |
    flutter build web --release --no-tree-shake-icons --base-href /ia-helper/app/
```

Note: No quotes needed in bash! The current workflow is correct.

For PowerShell (local testing):
```powershell
flutter build web --release --no-tree-shake-icons --base-href="/ia-helper/app/"
```

Note: Quotes required in PowerShell!

---

## ✅ Success Criteria

The web app is working when:

1. ✅ https://gameaday.github.io/ia-helper/app/ loads
2. ✅ No 404 errors in browser console
3. ✅ Flutter app renders with UI visible
4. ✅ Search, Discover, Library features work
5. ✅ Dark mode toggle works
6. ✅ Responsive on mobile and desktop

---

## 🎯 Most Likely Solution

Based on your description, the issue is almost certainly:

**GitHub Pages is not enabled in the repository settings.**

**The fix:**
1. Go to: https://github.com/Gameaday/ia-helper/settings/pages
2. Source: **"GitHub Actions"**
3. Save
4. Push a commit to trigger deployment
5. Wait 3-5 minutes
6. Visit https://gameaday.github.io/ia-helper/app/

**Why this is likely the issue:**
- ✅ Workflow file exists and looks correct
- ✅ Web app builds successfully locally
- ✅ Base-href is correct after rebuild
- ❌ But GitHub can't deploy without Pages enabled

---

## 📞 Next Steps

**Immediate:**
1. Check GitHub Pages settings (link above)
2. If not enabled, enable with "GitHub Actions" source
3. Push this commit to trigger deployment:
   ```bash
   git add .
   git commit -m "fix: Rebuild web with correct base-href, add deployment guides"
   git push origin main
   ```
4. Monitor: https://github.com/Gameaday/ia-helper/actions
5. Test: https://gameaday.github.io/ia-helper/app/

**If still not working after enabling Pages:**
- Share the workflow run logs
- Share any browser console errors
- We'll debug from there

---

**Current Status:** Ready to deploy! Just needs GitHub Pages enabled. 🚀
