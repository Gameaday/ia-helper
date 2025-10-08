# Visual Assets Creation - Master Checklist

**Status:** Specifications complete, assets pending creation  
**Last Updated:** January 15, 2025  
**Estimated Time:** 4-6 hours (DIY) or 2-3 days (hired designer)

---

## Quick Links

- **Detailed Guide:** `docs/features/VISUAL_ASSETS_GUIDE.md`
- **Icon Specs:** `assets/play_store/icon/README.md`
- **Feature Graphic Specs:** `assets/play_store/feature_graphic/README.md`
- **Phone Screenshots:** `assets/play_store/screenshots/phone/README.md`
- **Tablet Screenshots:** `assets/play_store/screenshots/tablet/README.md`

---

## Prerequisites Checklist

### Environment Setup
- [ ] Flutter app builds successfully in release mode
- [ ] Android emulator or physical device available (Pixel 6 Pro recommended)
- [ ] Design tool installed (choose one):
  - [ ] Figma (free account at https://figma.com)
  - [ ] GIMP (free at https://gimp.org)
  - [ ] Adobe Photoshop (if available)
- [ ] ImageMagick installed (optional, for verification)

### App Preparation
- [ ] Build release APK: `flutter build apk --release --flavor production`
- [ ] Install on device: `flutter install --flavor production`
- [ ] Populate sample data:
  - [ ] Search for "Public Domain Books" or "Classical Music"
  - [ ] Start 2-3 downloads
  - [ ] Add 5-6 favorites
  - [ ] Create 1-2 collections
- [ ] Verify NEW bottom navigation is working (5 tabs visible)

---

## Asset Creation Checklist

### Phase 1: App Icon (2-3 hours)

- [ ] Choose design concept (A, B, or C from guide)
- [ ] Open design tool (Figma/GIMP/Inkscape)
- [ ] Create new document: 512×512 pixels
- [ ] Design icon using Material Design 3 principles
- [ ] Use color palette:
  - Primary: `#2C5F9F`
  - Secondary: `#5E8CC2`
  - Accent: `#FF6B35`
- [ ] Keep important elements within 426×426px safe area
- [ ] Export as 32-bit PNG with alpha
- [ ] Save as `assets/play_store/icon/icon_512x512.png`
- [ ] Verify file size < 1MB
- [ ] Verify dimensions: `magick identify icon_512x512.png`

**Deliverable:** `assets/play_store/icon/icon_512x512.png` (512×512px)

---

### Phase 2: Feature Graphic (1-2 hours)

- [ ] Open design tool
- [ ] Create new document: 1024×500 pixels
- [ ] Add dark blue gradient background (`#2C5F9F` → `#1A3A5F`)
- [ ] Place app icon (256×256) on left side
- [ ] Add app name "IA Helper" (64px Roboto Bold, white)
- [ ] Add tagline "Download from Internet Archive" (32px Roboto Regular, white)
- [ ] Add screenshot preview on right (30% opacity)
- [ ] Add feature bullets with icons (24px Roboto Medium, white)
- [ ] Verify text contrast ratios (WCAG AA: 4.5:1 minimum)
- [ ] Export as PNG
- [ ] Save as `assets/play_store/feature_graphic/feature_1024x500.png`
- [ ] Verify exact dimensions (must be 1024×500)
- [ ] Verify file size < 1MB

**Deliverable:** `assets/play_store/feature_graphic/feature_1024x500.png` (1024×500px)

---

### Phase 3: Phone Screenshots (2-3 hours)

#### 3.1 Capture Raw Screenshots

- [ ] Launch app on device/emulator
- [ ] Navigate to Home screen (bottom nav: Home tab)
  - [ ] Capture: `screenshot_01_home_raw.png`
- [ ] Search for content, view results
  - [ ] Capture: `screenshot_02_search_results_raw.png`
- [ ] Open archive detail page
  - [ ] Capture: `screenshot_03_archive_detail_raw.png`
- [ ] Navigate to Transfers tab (bottom nav: Transfers)
  - [ ] Show active downloads with progress
  - [ ] Capture: `screenshot_04_transfers_raw.png`
- [ ] Navigate to Library tab (bottom nav: Library)
  - [ ] Show collections/downloads/favorites segmented control
  - [ ] Capture: `screenshot_05_library_raw.png`
- [ ] Navigate to Favorites tab (bottom nav: Favorites)
  - [ ] Show favorited items
  - [ ] Capture: `screenshot_06_favorites_raw.png`
- [ ] Open advanced search
  - [ ] Show filters and options
  - [ ] Capture: `screenshot_07_advanced_search_raw.png`
- [ ] Navigate to Settings tab (bottom nav: Settings)
  - [ ] Enable dark mode
  - [ ] Show settings options
  - [ ] Capture: `screenshot_08_settings_dark_raw.png`

#### 3.2 Add Text Overlays

For each screenshot:
- [ ] Open in design tool
- [ ] Add dark overlay bar at top (40% alpha black)
- [ ] Add white text (48-64px Roboto Bold):
  - Screenshot 1: "Explore 40M+ Items from Internet Archive"
  - Screenshot 2: "Search & Filter 40M+ Digital Items"
  - Screenshot 3: "View Detailed Metadata & Files"
  - Screenshot 4: "Manage Downloads with Queue & Priority"
  - Screenshot 5: "Organize Your Library by Collections"
  - Screenshot 6: "Save Favorites for Quick Access"
  - Screenshot 7: "Advanced Filters for Precise Search"
  - Screenshot 8: "Customize Downloads & Preferences"
- [ ] Verify text contrast (use https://webaim.org/resources/contrastchecker/)
- [ ] Export as PNG
- [ ] Save in `assets/play_store/screenshots/phone/`:
  - [ ] `01_home.png`
  - [ ] `02_search_results.png`
  - [ ] `03_archive_detail.png`
  - [ ] `04_transfers.png`
  - [ ] `05_library.png`
  - [ ] `06_favorites.png`
  - [ ] `07_advanced_search.png`
  - [ ] `08_settings_dark.png`

#### 3.3 Verify Phone Screenshots

- [ ] All 8 files exist in correct directory
- [ ] All dimensions ≥ 1080×1920 pixels
- [ ] All file sizes < 8MB
- [ ] All show NEW bottom navigation (5 tabs)
- [ ] Text overlays readable and properly contrasted
- [ ] No debug info or test data visible

**Deliverables:** 8 phone screenshots (1080×1920px minimum)

---

### Phase 4: Tablet Screenshots (1-2 hours)

#### 4.1 Set Up Tablet Emulator

- [ ] Launch tablet emulator (Pixel Tablet or Nexus 9)
- [ ] Install production build on tablet
- [ ] Populate with same sample data as phone

#### 4.2 Capture Raw Screenshots

- [ ] Home/search screen in landscape mode
  - [ ] Show two-pane layout if available
  - [ ] Capture: `screenshot_tablet_01_home_landscape_raw.png`
- [ ] Library with grid view (3-4 columns)
  - [ ] Portrait orientation
  - [ ] Capture: `screenshot_tablet_02_library_grid_raw.png`
- [ ] Transfers/downloads with expanded detail
  - [ ] Show more information than phone version
  - [ ] Capture: `screenshot_tablet_03_downloads_raw.png`
- [ ] Split-screen view (if implemented)
  - [ ] Search results + archive detail
  - [ ] Landscape orientation
  - [ ] Capture: `screenshot_tablet_04_split_view_raw.png`

#### 4.3 Add Text Overlays

For each tablet screenshot:
- [ ] Open in design tool
- [ ] Add dark overlay bar (40% alpha black)
- [ ] Add white text (64-96px Roboto Bold, larger than phone):
  - Screenshot 1: "Optimized for Tablets & Large Screens"
  - Screenshot 2: "Browse Collections in Grid View"
  - Screenshot 3: "Manage Multiple Downloads Efficiently"
  - Screenshot 4: "Split-Screen Multitasking"
- [ ] Verify text contrast
- [ ] Export as PNG
- [ ] Save in `assets/play_store/screenshots/tablet/`:
  - [ ] `01_home_landscape.png`
  - [ ] `02_library_grid.png`
  - [ ] `03_downloads.png`
  - [ ] `04_split_view.png`

#### 4.4 Verify Tablet Screenshots

- [ ] All 4 files exist in correct directory
- [ ] All dimensions ≥ 1536×2048 (portrait) or 2048×1536 (landscape)
- [ ] All file sizes < 8MB
- [ ] Show tablet-optimized layouts (not just scaled phone UI)
- [ ] Text overlays readable and properly contrasted

**Deliverables:** 4 tablet screenshots (1536×2048px or 2048×1536px)

---

## Verification Checklist

### File Structure
```
assets/play_store/
├── icon/
│   └── icon_512x512.png ✓
├── feature_graphic/
│   └── feature_1024x500.png ✓
└── screenshots/
    ├── phone/
    │   ├── 01_home.png ✓
    │   ├── 02_search_results.png ✓
    │   ├── 03_archive_detail.png ✓
    │   ├── 04_transfers.png ✓
    │   ├── 05_library.png ✓
    │   ├── 06_favorites.png ✓
    │   ├── 07_advanced_search.png ✓
    │   └── 08_settings_dark.png ✓
    └── tablet/
        ├── 01_home_landscape.png ✓
        ├── 02_library_grid.png ✓
        ├── 03_downloads.png ✓
        └── 04_split_view.png ✓
```

### Technical Verification

Run these commands to verify all assets:

```powershell
# Check icon
magick identify assets/play_store/icon/icon_512x512.png
# Expected: PNG 512x512, < 1MB

# Check feature graphic
magick identify assets/play_store/feature_graphic/feature_1024x500.png
# Expected: PNG 1024x500, < 1MB

# Check phone screenshots
magick identify assets/play_store/screenshots/phone/*.png
# Expected: 8 files, each ≥ 1080x1920, < 8MB

# Check tablet screenshots
magick identify assets/play_store/screenshots/tablet/*.png
# Expected: 4 files, each ≥ 1536x2048, < 8MB
```

### Quality Verification

- [ ] All images use correct color space (sRGB)
- [ ] No compression artifacts visible
- [ ] Text is crisp and readable at full resolution
- [ ] Colors match brand guidelines
- [ ] App icon recognizable at small sizes (48×48)
- [ ] Feature graphic text readable in Play Store preview
- [ ] Screenshots show real functionality (not mockups)
- [ ] Bottom navigation visible in phone screenshots
- [ ] Tablet screenshots show responsive layouts
- [ ] Dark mode screenshot properly themed

### Accessibility Verification

- [ ] Text contrast ratios ≥ 4.5:1 (WCAG AA)
  - Use: https://webaim.org/resources/contrastchecker/
- [ ] Text overlays don't obscure important UI elements
- [ ] Colors don't rely solely on hue for meaning
- [ ] Icon recognizable in both light and dark themes

---

## Alternative: Hiring a Designer

If you prefer to outsource asset creation:

### What to Do
1. [ ] Post job on Fiverr/Upwork/99designs
2. [ ] Provide this checklist + VISUAL_ASSETS_GUIDE.md
3. [ ] Provide production APK or raw screenshots
4. [ ] Specify timeline (2-3 days typical)
5. [ ] Budget: $50-150 for complete package

### What to Request from Designer
- [ ] App icon source file (PSD/AI/FIG)
- [ ] App icon PNG export (512×512)
- [ ] Feature graphic source file
- [ ] Feature graphic PNG export (1024×500)
- [ ] 8 phone screenshots with text overlays
- [ ] 4 tablet screenshots with text overlays
- [ ] All editable source files for future updates

---

## Success Criteria

**All assets complete when:**
- ✅ 1 app icon (512×512)
- ✅ 1 feature graphic (1024×500)
- ✅ 8 phone screenshots (≥1080×1920)
- ✅ 4 tablet screenshots (≥1536×2048)
- ✅ All files under size limits
- ✅ All files in correct directories
- ✅ All technical specifications met
- ✅ All quality checks passed
- ✅ Ready for Play Store upload

**Total Files:** 14 (1 icon + 1 graphic + 8 phone + 4 tablet)

---

## Time Estimates

| Phase | DIY Time | Hired Time |
|-------|----------|------------|
| App Icon | 2-3 hours | Included |
| Feature Graphic | 1-2 hours | Included |
| Phone Screenshots | 2-3 hours | Included |
| Tablet Screenshots | 1-2 hours | Included |
| **Total** | **6-10 hours** | **2-3 days** |

**Cost (Hired):** $50-150 on Fiverr/Upwork

---

## Next Steps After Completion

Once all assets are created and verified:

1. [ ] Update `PHASE_5_TASK_1_PROGRESS.md` to mark Task 1.6 complete
2. [ ] Commit all assets to repository
3. [ ] Create completion report: `docs/features/TASK_1_6_COMPLETE.md`
4. [ ] Proceed to production signing setup (Task 1.7)
5. [ ] Begin device testing (Task 1.8)
6. [ ] Prepare for Play Store submission (Phase 5 Task 6)

---

## Resources

**Design Tools:**
- Figma: https://figma.com
- GIMP: https://gimp.org
- Inkscape: https://inkscape.org

**Screenshot Tools:**
- Android Studio Device Manager (built-in)
- scrcpy: https://github.com/Genymobile/scrcpy

**Verification Tools:**
- ImageMagick: https://imagemagick.org/
- Contrast Checker: https://webaim.org/resources/contrastchecker/

**Reference:**
- Material Design 3: https://m3.material.io/
- Play Store Guidelines: https://support.google.com/googleplay/android-developer/answer/9866151
- Internet Archive: https://archive.org/

---

**Document Status:** Complete ✅  
**Assets Status:** Awaiting creation  
**Blocking:** Play Store submission until complete  
**Priority:** High - Only remaining blocker for Task 1
