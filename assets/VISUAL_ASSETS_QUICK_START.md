# Visual Assets Quick Start Guide

**Date**: October 10, 2025  
**Phase 5 Progress**: 95% Complete  
**Next Critical Step**: Create Play Store visual assets

---

## 🎯 What You Need to Create

### Required Assets (4 types):
1. **App Icon** - 512×512px PNG ✅ Template ready in `assets/icons/ic_launcher_1024.png`
2. **Feature Graphic** - 1024×500px PNG/JPEG
3. **Phone Screenshots** - 8 images, 1080×1920px minimum
4. **Tablet Screenshots** - 4 images, 1536×2048px minimum

**Total Time Estimate**: 4-6 hours

---

## 🚀 Quick Start: Screenshots (Start Here!)

Screenshots are the easiest to create since the app is already built and responsive.

### Step 1: Run the App (5 minutes)

**On Phone Emulator:**
```powershell
# Start Pixel 6 Pro emulator in Android Studio
flutter run --release
```

**On Tablet Emulator:**
```powershell
# Start Pixel Tablet emulator in Android Studio
flutter run --release
```

### Step 2: Prepare Sample Data (10 minutes)

Navigate through the app and create sample data:

1. **Home Screen**: 
   - Search for "nasa" → capture search interface
   - View recent searches

2. **Search Results**:
   - Show grid layout with thumbnails
   - Demonstrate responsive columns (2-5 based on width)

3. **Archive Detail**:
   - Open a result → show metadata and files
   - Demonstrate side-by-side layout on tablet

4. **Library Screen**:
   - Add 5-6 favorites
   - Create 1-2 collections
   - Show grid layout

5. **Transfers Screen**:
   - Start 2-3 downloads
   - Show progress bars and metadata

6. **Discover Screen**:
   - Show featured collections
   - Demonstrate responsive grid

7. **More/Settings Screen**:
   - Show settings menu
   - Demonstrate grid layout on tablet

### Step 3: Capture Screenshots (30 minutes)

**Method 1: Android Studio**
1. View → Tool Windows → Running Devices
2. Click camera icon for screenshot
3. Save as PNG

**Method 2: Device Built-in**
- Press Power + Volume Down
- Find in Pictures/Screenshots folder

**Naming Convention**:
```
phone_01_home.png
phone_02_search_results.png
phone_03_archive_detail.png
phone_04_library.png
phone_05_transfers.png
phone_06_discover.png
phone_07_settings.png
phone_08_advanced_search.png

tablet_01_home_landscape.png
tablet_02_library_grid.png
tablet_03_transfers_multi.png
tablet_04_split_view.png
```

### Step 4: Add Text Overlays (2 hours)

Use **Figma** (easiest, free) or **Photoshop** or **GIMP**:

1. Import screenshot
2. Add dark overlay bar at top (60% opacity black)
3. Add white text (48-64px Roboto Bold)
4. Ensure good contrast (WCAG AA: 4.5:1)

**Text for Each Screenshot**:
- Home: "Search 40+ Million Items from Internet Archive"
- Search Results: "Browse Collections in Beautiful Grid Layouts"
- Archive Detail: "View Detailed Metadata & Download Files"
- Library: "Organize Favorites & Build Collections"
- Transfers: "Manage Downloads with Progress Tracking"
- Discover: "Explore Trending & Featured Collections"
- Settings: "Customize Your Experience"
- Advanced Search: "Powerful Search with 20+ Fields"

**Tablet Screens**:
- Home (Landscape): "Optimized for Tablets & Large Screens"
- Library Grid: "See More Content in Responsive Grid Layout"
- Transfers Multi: "Manage Multiple Downloads Efficiently"
- Split View: "Professional Split-Screen Experience"

---

## 🎨 Feature Graphic (1.5 hours)

**Dimensions**: 1024×500px

**Design Concept**:
```
┌─────────────────────────────────────────┐
│ Left (400px):                           │
│   App Icon (large)                      │
│   "IA Helper"                           │
│   "Internet Archive Mobile App"         │
│                                         │
│ Right (624px):                          │
│   Overlapping phone/tablet mockups      │
│   showing the app in action             │
│   Gradient background (blue → purple)   │
└─────────────────────────────────────────┘
```

**Quick Method**:
1. Use Figma template: https://www.figma.com/community/search?model_type=hub_files&q=feature%20graphic
2. Replace content with IA Helper branding
3. Add Internet Archive blue color (#2C5F9F)
4. Export as PNG at 1024×500px

**Assets Needed**:
- App icon (already exists: `assets/icons/ic_launcher_1024.png`)
- 2-3 phone mockups from screenshots above
- Internet Archive logo (available at `assets/icons/internet_archive_logo.svg`)

---

## 🖼️ App Icon (1.5 hours)

**Current Status**: ic_launcher_1024.png exists but may need refinement

**Check Current Icon**:
```powershell
cd c:\Project\ia-helper\assets\icons
# View ic_launcher_1024.png in image viewer
```

**If Refinement Needed**:

**Option A: Use Existing + Refine**
1. Open ic_launcher_1024.png in Figma/GIMP
2. Resize to 512×512px (Play Store requirement)
3. Ensure safe area (426×426px center)
4. Export as 32-bit PNG with alpha

**Option B: Create New Icon**
Use one of the concepts from VISUAL_ASSETS_GUIDE.md:
- Archive Logo Focus (temple + "IA")
- Download + Archive (arrow + temple)
- Minimalist ("IA" lettermark)

**Color Palette**:
- Primary: #2C5F9F (Internet Archive blue)
- Secondary: #5E8CC2 (lighter blue)
- Accent: #FF6B35 (orange for download indicator)

**Tool Options**:
- Figma: https://figma.com (free, easiest)
- GIMP: https://gimp.org (free, powerful)
- Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/

---

## 📋 Complete Workflow Summary

### Timeline (4-6 hours total):

**Hour 1: Setup & Screenshots**
- ✅ Set up emulators (Pixel 6 Pro + Pixel Tablet)
- ✅ Run app in release mode
- ✅ Create sample data across all screens
- ✅ Capture 12 raw screenshots (8 phone + 4 tablet)

**Hour 2-3: Screenshot Editing**
- ✅ Import screenshots to Figma/Photoshop/GIMP
- ✅ Add text overlays to all 12 screenshots
- ✅ Ensure proper contrast and readability
- ✅ Export final screenshots as PNG

**Hour 4: Feature Graphic**
- ✅ Create 1024×500px feature graphic in Figma
- ✅ Combine app icon, mockups, and branding
- ✅ Export as PNG or JPEG (under 1MB)

**Hour 5: App Icon**
- ✅ Refine existing icon OR create new
- ✅ Export as 512×512px PNG with alpha
- ✅ Test on different backgrounds (light/dark)

**Hour 6: Quality Check**
- ✅ Verify all assets meet Play Store requirements
- ✅ Check file sizes (under limits)
- ✅ Review on different displays
- ✅ Organize files for upload

---

## 📁 File Organization

Create this folder structure:

```
assets/play_store/
├── app_icon_512.png              (512×512, <1MB)
├── feature_graphic.png           (1024×500, <1MB)
├── phone/
│   ├── 01_home.png               (1080×1920+)
│   ├── 02_search_results.png
│   ├── 03_archive_detail.png
│   ├── 04_library.png
│   ├── 05_transfers.png
│   ├── 06_discover.png
│   ├── 07_settings.png
│   └── 08_advanced_search.png
└── tablet/
    ├── 01_home_landscape.png     (1536×2048+ or 2048×1536+)
    ├── 02_library_grid.png
    ├── 03_transfers_multi.png
    └── 04_split_view.png
```

---

## ✅ Quality Checklist

Before uploading to Play Store:

### App Icon
- [ ] 512×512px dimensions
- [ ] 32-bit PNG with alpha channel
- [ ] File size under 1MB
- [ ] Important elements within 426×426px safe area
- [ ] Looks good on white and colored backgrounds

### Feature Graphic
- [ ] 1024×500px dimensions
- [ ] PNG or JPEG format
- [ ] File size under 1MB
- [ ] No important text/icons near edges
- [ ] Readable at small sizes

### Phone Screenshots (All 8)
- [ ] Minimum 1080×1920px
- [ ] PNG format
- [ ] File size under 8MB each
- [ ] Text overlays readable and high contrast
- [ ] Shows variety of features
- [ ] Bottom navigation visible
- [ ] No sensitive/test data visible

### Tablet Screenshots (All 4)
- [ ] Minimum 1536×2048px (or 2048×1536px landscape)
- [ ] PNG format
- [ ] File size under 8MB each
- [ ] Demonstrates responsive layouts
- [ ] Shows tablet-specific features
- [ ] Text overlays readable

---

## 🎨 Design Tools Comparison

| Tool | Free? | Ease | Best For |
|------|-------|------|----------|
| **Figma** | ✅ Yes | ⭐⭐⭐⭐⭐ | Everything! Web-based, templates available |
| **Canva** | ✅ Yes | ⭐⭐⭐⭐⭐ | Feature graphic, simple overlays |
| **GIMP** | ✅ Yes | ⭐⭐⭐ | Screenshot editing, icon creation |
| **Inkscape** | ✅ Yes | ⭐⭐⭐ | Vector icon design |
| **Photoshop** | ❌ Paid | ⭐⭐⭐⭐ | Professional editing, all tasks |
| **Android Asset Studio** | ✅ Yes | ⭐⭐⭐⭐⭐ | Quick icon generation |

**Recommendation**: Start with **Figma** (free, web-based, easiest)

---

## 🔗 Quick Links

- **Play Store Requirements**: https://support.google.com/googleplay/android-developer/answer/9866151
- **Material Design 3**: https://m3.material.io/
- **Figma**: https://figma.com
- **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/
- **GIMP**: https://gimp.org

---

## 💡 Pro Tips

1. **Take Screenshots in Release Mode** - Better performance, no debug banners
2. **Use Real Content** - Avoid "Lorem ipsum" or "Test" data
3. **Show Variety** - Different screens, features, use cases
4. **Highlight Unique Features** - Smart search, responsive layouts, offline support
5. **Maintain Consistency** - Same style for all text overlays
6. **Test on Different Displays** - Verify readability on small/large screens
7. **Keep Source Files** - Save Figma/PSD files for future updates

---

## ❓ Common Questions

**Q: Do I need exactly 8 phone screenshots?**  
A: Minimum 2, maximum 8. We recommend 8 to showcase all features.

**Q: Can I use landscape orientation for phone?**  
A: Yes! Mix portrait and landscape to show responsive design.

**Q: What if my tablet screenshots are too large?**  
A: Resize maintaining aspect ratio, or crop to focus on important areas.

**Q: Do I need a promotional video?**  
A: Optional, not required for initial launch. Can add later.

**Q: Can I update assets after launch?**  
A: Yes! Update anytime in Play Console.

---

## 🚀 Next Steps After Assets Complete

1. Upload assets to Play Console
2. Final testing round on device
3. Performance optimization check
4. Merge smart-search to main
5. Create release build (AAB)
6. Submit for Play Store review

**Estimated Time to Launch After Assets**: 6-9 hours

---

**Status**: Phase 5 is 95% complete. Visual assets are the final blocker for Play Store submission. You've got this! 🎉

**Questions?** Refer to the comprehensive guide: `docs/features/VISUAL_ASSETS_GUIDE.md`
