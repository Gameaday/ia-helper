# Quick Testing Guide for ia-helper v1.6.0

## Testing URL
🌐 **Live App:** https://gameaday.github.io/ia-helper/app/

## Quick Test Scenarios (15-20 minutes)

### 1. CORS Fix Verification (CRITICAL) ⚡
**Expected:** Search and browse work on web without errors
1. Open web app
2. Open browser console (F12)
3. Search for something (e.g., "nasa")
4. **✅ SUCCESS:** Results load without CORS errors
5. **❌ FAILURE:** Red CORS errors in console

### 2. More Menu Navigation 🧭
**Expected:** All new screens accessible and functional
1. Tap "More" tab (bottom navigation)
2. Tap each menu item:
   - Data & Storage ➔ Should show storage stats
   - Statistics ➔ Should show download/search stats
   - API Settings ➔ Should show settings controls
   - IA Health Status ➔ Should check endpoints
   - About ➔ Should show app version and info
3. **✅ SUCCESS:** All screens load, back button works

### 3. User-Agent Settings (NEW FEATURE) 🆕
**Expected:** User-Agent visible and editable
1. More ➔ API Settings
2. Scroll to "Identification" section
3. **Check:** User-Agent displays (default or custom)
4. Tap User-Agent item
5. **Check:** Dialog opens with editing capability
6. Try editing User-Agent, save
7. **Check:** Custom User-Agent persists
8. **✅ SUCCESS:** User-Agent customizable and persistent

### 4. IA Health Status 🏥
**Expected:** Real-time endpoint checking
1. More ➔ IA Health Status
2. **Check:** 4 endpoints display with status
3. **Check:** Response times shown (milliseconds)
4. **Check:** Color coding (green=good, red=bad)
5. Pull down to refresh
6. **Check:** Status updates
7. **✅ SUCCESS:** Health monitoring works

### 5. API Settings Persistence 💾
**Expected:** Settings save and load correctly
1. More ➔ API Settings
2. Toggle "Reduced Priority"
3. Change "Requests per Minute" to 10
4. Toggle "Send Do Not Track"
5. Close app completely
6. Reopen app
7. More ➔ API Settings
8. **Check:** All settings still set as changed
9. **✅ SUCCESS:** Settings persist

### 6. Data Storage Management 🗄️
**Expected:** Cache management functional
1. More ➔ Data & Storage
2. **Check:** Storage stats display
3. Tap "Clear Metadata Cache"
4. **Check:** Confirmation dialog appears
5. Confirm clear
6. **Check:** Cache size updates
7. **✅ SUCCESS:** Cache management works

### 7. Statistics Display 📊
**Expected:** Statistics show (even if mock data)
1. More ➔ Statistics
2. **Check:** Download statistics visible
3. **Check:** Search activity visible
4. **Check:** Library statistics visible
5. **Check:** Storage statistics visible
6. Pull down to refresh
7. **✅ SUCCESS:** Statistics display properly

### 8. About Screen Information ℹ️
**Expected:** App info displays correctly
1. More ➔ About
2. **Check:** Version number displays
3. **Check:** Features list visible
4. **Check:** Credits section present
5. Tap "Privacy Policy"
6. **Check:** Privacy policy loads
7. **✅ SUCCESS:** About screen complete

## Platform-Specific Tests

### Web Only 🌐
- [ ] User-Agent shows "(Native platforms only)" note
- [ ] No User-Agent sent in requests (check Network tab)
- [ ] No CORS errors in console
- [ ] All features work despite no User-Agent

### Mobile/Desktop 📱💻
- [ ] User-Agent sent with requests
- [ ] Custom User-Agent editable and saved
- [ ] No web-specific limitations

## Regression Testing (10 minutes)

### Core Features Still Work
- [ ] Search Internet Archive
- [ ] View item details
- [ ] Download files
- [ ] Save to library
- [ ] Mark favorites
- [ ] View search history
- [ ] Navigate between tabs

## Known Non-Issues ✅

1. **"flutter_markdown discontinued" warning:**
   - Expected, doesn't affect functionality
   - Can ignore safely

2. **"pdfx wasm" warnings during build:**
   - Expected, doesn't affect current web build
   - Can ignore safely

3. **Transitive dependencies outdated:**
   - Expected, not blocking
   - Direct dependencies all up-to-date

## Bug Reporting Template

If you find issues, please report with:

```
**Issue:** [Brief description]
**Platform:** [Web/Android/iOS/Windows/macOS/Linux]
**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected:** [What should happen]
**Actual:** [What actually happens]
**Console Errors:** [Any errors in browser console]
```

## Quick Pass/Fail Criteria

### ✅ PASS if:
- Web app loads on GitHub Pages
- Search works without CORS errors
- All More menu items navigate properly
- API Settings save and load
- IA Health Status checks endpoints
- User-Agent displays and edits correctly

### ❌ FAIL if:
- CORS errors prevent API access
- Any screen crashes on load
- Settings don't persist after restart
- Health checks fail for all endpoints
- Navigation breaks

## Testing Priority

1. **🔴 CRITICAL:** CORS fix (search must work on web)
2. **🟠 HIGH:** More menu navigation (all screens load)
3. **🟠 HIGH:** API Settings persistence (save/load works)
4. **🟡 MEDIUM:** User-Agent customization (display/edit)
5. **🟡 MEDIUM:** IA Health Status (endpoint checks)
6. **🟢 LOW:** Statistics display (mock data OK)
7. **🟢 LOW:** About screen (informational only)

## Estimated Testing Time

- **Quick Test:** 15-20 minutes (scenarios 1-8)
- **Thorough Test:** 45-60 minutes (all scenarios + regression)
- **Full Platform Test:** 2+ hours (test on multiple platforms)

## After Testing

**If all tests pass:**
✅ App ready for production release
✅ Can share link publicly
✅ Move to Phase 5 Task 2

**If issues found:**
🔧 Report issues with bug template
🔧 Prioritize fixes based on severity
🔧 Retest after fixes

---

**Last Build:** January 2025
**Flutter Version:** 3.35.5
**Dart Version:** 3.9.2
