# Visual Assets Creation Guide

**Status:** Placeholder specifications created ✅  
**Final Assets:** TODO - Need design tools (Figma/Photoshop/GIMP)  
**Estimated Time:** 4-6 hours with design tools

---

## Overview

This guide provides complete specifications for creating all Play Store visual assets. The navigation redesign is now complete, so screenshots will showcase the new bottom navigation system.

---

## Asset Checklist

### Required for Play Store
- [ ] App Icon (512×512px, 32-bit PNG with alpha)
- [ ] Feature Graphic (1024×500px, PNG or JPEG)
- [ ] Phone Screenshots (8 images, 1080×1920px minimum)
- [ ] Tablet Screenshots (4 images, 1536×2048px minimum)

### Optional but Recommended
- [ ] Promotional Graphic (180×120px)
- [ ] TV Banner (1280×720px, if supporting Android TV)

---

## 1. App Icon Specifications

### Technical Requirements
- **Size:** 512×512 pixels
- **Format:** 32-bit PNG with alpha channel
- **File size:** Under 1MB
- **Safe area:** Keep important elements within 426×426px center

### Design Guidelines

**Style:** Material Design 3 with Internet Archive branding

**Concept Options:**

#### Option A: Archive Logo Focus
```
┌─────────────────────┐
│                     │
│   ┌───────────┐     │
│   │    ⌒      │     │  Internet Archive temple icon
│   │   ╱ ╲     │     │  with "IA" letters overlaid
│   │  ╱   ╲    │     │  
│   │ /─────\   │     │  
│   │ │ I A │   │     │  
│   └─────────┘─┘     │
│                     │
└─────────────────────┘
```

#### Option B: Download + Archive
```
┌─────────────────────┐
│                     │
│       ↓             │  Download arrow combining
│      ╱╲╲            │  with archive temple
│     ╱  ╲╲           │  Modern, action-oriented
│    ╱____╲╲          │  
│    │ I A ││         │  
│    └──────┘         │
│                     │
└─────────────────────┘
```

#### Option C: Minimalist
```
┌─────────────────────┐
│                     │
│                     │
│        IA           │  Simple "IA" lettermark
│       ─────         │  with download indicator
│         ↓           │  Clean, modern
│                     │  
│                     │
│                     │
└─────────────────────┘
```

**Color Palette (Material Design 3):**
- Primary: `#2C5F9F` (Internet Archive blue)
- Secondary: `#5E8CC2` (lighter blue)
- Accent: `#FF6B35` (orange for download indicator)
- Background: White or transparent
- Dark mode variant: Consider dark background with light icon

**Typography:**
- If using text, use Roboto Bold or similar sans-serif
- Letter spacing: -2% to -5% for compactness

### Tools for Creation
- **Figma:** https://figma.com (free tier available)
- **GIMP:** https://gimp.org (free, open source)
- **Inkscape:** https://inkscape.org (free, vector graphics)
- **Adobe Illustrator:** Professional option

### Export Settings
- Resolution: 512×512px @1x
- Format: PNG-24 with alpha
- Color space: sRGB
- No compression artifacts

---

## 2. Feature Graphic Specifications

### Technical Requirements
- **Size:** 1024×500 pixels
- **Format:** PNG or JPEG (PNG preferred for text clarity)
- **File size:** Under 1MB
- **Aspect ratio:** Must be exactly 1024:500

### Design Guidelines

**Purpose:** Hero image displayed at top of Play Store listing

**Layout Concept:**
```
┌──────────────────────────────────────────────────────┐
│  [App Icon]                                          │
│                                                      │
│  IA Helper                                           │
│  Download from Internet Archive                      │
│                                                      │
│  [Screenshot Preview]  • Fast Downloads              │
│                        • Search & Filter             │
│                        • Library Management          │
└──────────────────────────────────────────────────────┘
```

**Content Elements:**
1. **Left side (500×500px):**
   - App icon at 256×256px
   - App name "IA Helper" in large font
   - Tagline "Download from Internet Archive"

2. **Right side (524×500px):**
   - Screenshot preview (blurred/faded)
   - Key feature bullets with icons
   - Material Design 3 cards/elevation

**Color Scheme:**
- Background gradient: `#2C5F9F` → `#1A3A5F` (dark blue)
- Text: White with proper contrast (WCAG AA)
- Accents: Orange `#FF6B35` for highlights
- Screenshot overlay: 30% opacity white

**Typography:**
- App name: 64px, Roboto Bold
- Tagline: 32px, Roboto Regular
- Features: 24px, Roboto Medium

### Alternative Designs

#### Design A: App Showcase
- Large phone mockup showing app interface
- Floating UI elements highlighting key features
- Modern, dynamic composition

#### Design B: Feature Grid
- 3×2 grid of feature icons
- Each with label and micro-description
- Clean, organized, informative

#### Design C: Hero Screenshot
- Full-width screenshot of app in use
- Gradient overlay with text
- "Screenshot first" approach

---

## 3. Phone Screenshots Specifications

### Technical Requirements
- **Size:** Minimum 1080×1920px (can be larger)
- **Aspect ratio:** 9:16 (standard phone portrait)
- **Format:** PNG or JPEG (PNG for text overlays)
- **Count:** Minimum 2, recommended 8
- **File size:** Under 8MB each

### Screenshot Plan (8 Images)

#### Screenshot 1: Home Screen - NEW NAVIGATION ⭐
**Purpose:** Show bottom navigation and search

**Capture:**
- Bottom navigation visible with Home tab active
- Search bar prominent in app bar
- Recent searches or suggested content visible
- Clean, uncluttered first impression

**Text Overlay:**
- "Explore 40M+ Items from Internet Archive"
- Positioned at top third

#### Screenshot 2: Search Results
**Purpose:** Demonstrate search functionality

**Capture:**
- Search results for popular query (e.g., "Public Domain Books")
- Multiple result cards visible
- Filter button in app bar highlighted
- NEW: Bottom navigation showing Search/Library tab

**Text Overlay:**
- "Search & Filter 40M+ Digital Items"

#### Screenshot 3: Archive Detail
**Purpose:** Show metadata and download options

**Capture:**
- Archive detail screen with clear metadata
- File list visible
- Download button prominent
- Back navigation via app bar

**Text Overlay:**
- "View Detailed Metadata & Files"

#### Screenshot 4: Transfers Screen - NEW NAVIGATION ⭐
**Purpose:** Highlight NEW transfers tab with downloads

**Capture:**
- Bottom navigation with Transfers tab active
- Segmented control showing Active/Completed/Failed/Queue
- Multiple downloads in progress with progress bars
- Pause/resume controls visible

**Text Overlay:**
- "Manage Downloads with Queue & Priority"

#### Screenshot 5: Library Screen - NEW NAVIGATION ⭐
**Purpose:** Show library organization

**Capture:**
- Bottom navigation with Library tab active
- Segmented control: Collections/Downloads/Favorites
- Grid or list of saved items
- Search within library

**Text Overlay:**
- "Organize Your Library by Collections"

#### Screenshot 6: Favorites Screen - NEW NAVIGATION ⭐
**Purpose:** Show favorites feature

**Capture:**
- Bottom navigation with Favorites tab active
- List of favorited archives
- Heart icons visible
- Quick access emphasis

**Text Overlay:**
- "Save Favorites for Quick Access"

#### Screenshot 7: Advanced Search
**Purpose:** Show advanced filtering

**Capture:**
- Advanced search screen or modal
- Multiple filter options visible:
  - Media type
  - Date range
  - Collection
  - Sort options
- Material Design 3 chips/selectors

**Text Overlay:**
- "Advanced Filters for Precise Search"

#### Screenshot 8: Settings Screen - NEW NAVIGATION ⭐
**Purpose:** Show customization and dark mode

**Capture:**
- Bottom navigation with Settings tab active
- Dark mode toggle visible and ENABLED
- Other settings visible:
  - Download preferences
  - Storage location
  - Bandwidth limits
- Material Design 3 switches/sliders

**Text Overlay:**
- "Customize Downloads & Preferences"

### Screenshot Capture Process

#### Step 1: Prepare App for Screenshots
1. Use Production flavor build
2. Clear any test data
3. Pre-populate with good sample content:
   - Search for "Public Domain Books" or "Classical Music"
   - Start 2-3 downloads
   - Add 5-6 favorites
   - Create 1-2 collections

#### Step 2: Set Up Emulator/Device
```powershell
# Use Android Studio emulator
# Recommended device: Pixel 6 Pro (1440 x 3120, 560 dpi)
# Take screenshots at native resolution, crop to 1080x1920

flutter run --release --flavor production
```

#### Step 3: Capture Screenshots
- Use Android Studio: View → Tool Windows → Running Devices → Screenshot
- Or use device built-in: Power + Volume Down
- Save as PNG files named: `screenshot_01_home.png` through `screenshot_08_settings.png`

#### Step 4: Add Text Overlays
Use Figma/Photoshop/GIMP to add:
- Semi-transparent dark overlay bar at top
- White text (48-64px Roboto Bold)
- Icon if applicable (Material Icons)
- Ensure WCAG AA contrast (4.5:1 minimum)

### Screenshot Design Template
```
┌─────────────────────────────────┐
│ ╔═════════════════════════════╗ │ <- Dark overlay bar (alpha 60%)
│ ║ "Feature Description Text"  ║ │    with white text
│ ╚═════════════════════════════╝ │
│                                 │
│                                 │
│    [ACTUAL APP SCREENSHOT]      │
│                                 │
│                                 │
│                                 │
│                                 │
│    ┌───┬───┬───┬───┬───┐       │ <- Bottom nav bar visible
│    │ H │ L │ F │ T │ S │       │    showing current tab
│    └───┴───┴───┴───┴───┘       │
└─────────────────────────────────┘
```

---

## 4. Tablet Screenshots Specifications

### Technical Requirements
- **Size:** Minimum 1536×2048px (7-inch portrait)
- **Alternative:** 2048×1536px (10-inch landscape)
- **Format:** PNG or JPEG
- **Count:** Minimum 2, recommended 4
- **File size:** Under 8MB each

### Tablet Screenshot Plan (4 Images)

#### Screenshot 1: Home/Search (Landscape or Portrait)
**Purpose:** Show adaptive layout for tablets

**Capture:**
- Wider layout with more content visible
- Two-pane layout if applicable (master-detail)
- Bottom navigation adjusted for tablet
- Search bar and results side-by-side if landscape

**Text Overlay:**
- "Optimized for Tablets & Large Screens"

#### Screenshot 2: Library Grid View
**Purpose:** Show grid layout optimization

**Capture:**
- Library screen with 3-4 column grid
- More items visible than phone
- Proper spacing and padding
- Bottom navigation

**Text Overlay:**
- "Browse Collections in Grid View"

#### Screenshot 3: Download Management
**Purpose:** Show transfers with more detail

**Capture:**
- Transfers screen with expanded information
- Multiple downloads with metadata visible
- Progress bars, file sizes, timestamps
- Possible two-pane: queue list + selected detail

**Text Overlay:**
- "Manage Multiple Downloads Efficiently"

#### Screenshot 4: Split View (Landscape)
**Purpose:** Show advanced tablet features

**Capture:**
- Search results on left (40% width)
- Archive detail on right (60% width)
- Demonstrates responsive design
- Professional, desktop-like layout

**Text Overlay:**
- "Split-Screen Multitasking"

---

## 5. Asset Organization

### Directory Structure
```
assets/play_store/
├── icon/
│   ├── icon_512x512.png          # App icon (final)
│   ├── icon_512x512_draft.png    # Draft version
│   └── icon_source.fig           # Figma source (if used)
├── feature_graphic/
│   ├── feature_1024x500.png      # Feature graphic (final)
│   ├── feature_1024x500_draft.png
│   └── feature_source.fig
├── screenshots/
│   ├── phone/
│   │   ├── 01_home.png
│   │   ├── 02_search_results.png
│   │   ├── 03_archive_detail.png
│   │   ├── 04_transfers.png
│   │   ├── 05_library.png
│   │   ├── 06_favorites.png
│   │   ├── 07_advanced_search.png
│   │   └── 08_settings_dark.png
│   └── tablet/
│       ├── 01_home_landscape.png
│       ├── 02_library_grid.png
│       ├── 03_downloads.png
│       └── 04_split_view.png
└── templates/
    ├── screenshot_overlay_template.fig
    └── text_overlay_guide.md
```

### Naming Conventions
- Use descriptive names with numbers
- Format: `{sequence}_{screen_name}_{variant?}.png`
- Examples:
  - `01_home_light.png`
  - `01_home_dark.png`
  - `04_transfers_active_queue.png`

---

## 6. Quick Start Checklist

### Prerequisites
- [ ] Flutter app built in release mode (`flutter build apk --release --flavor production`)
- [ ] Android emulator or physical device ready (Pixel 6 Pro recommended)
- [ ] Design tool installed (Figma free account or GIMP)
- [ ] Sample content prepared in app (searches, downloads, favorites)

### Phase 1: Capture (1-2 hours)
- [ ] Launch app on device/emulator
- [ ] Navigate to each of 8 screens
- [ ] Capture clean screenshots (no debug info)
- [ ] Verify screenshots show NEW bottom navigation
- [ ] Save as PNG files in organized folders

### Phase 2: Design Icon & Feature Graphic (2-3 hours)
- [ ] Choose icon design concept (A, B, or C)
- [ ] Create 512×512 icon in design tool
- [ ] Export icon as PNG with alpha
- [ ] Design 1024×500 feature graphic
- [ ] Add text overlays and app preview
- [ ] Export feature graphic as PNG

### Phase 3: Polish Screenshots (1-2 hours)
- [ ] Open screenshots in design tool
- [ ] Add dark overlay bar at top (40% alpha)
- [ ] Add white text (48-64px Roboto Bold)
- [ ] Verify text contrast (WCAG AA: 4.5:1 minimum)
- [ ] Add icons if applicable
- [ ] Export all 8 phone screenshots
- [ ] Export all 4 tablet screenshots

### Phase 4: Verification
- [ ] Check all file sizes (under limits)
- [ ] Verify exact dimensions (use ImageMagick or similar)
- [ ] Test contrast ratios for text overlays
- [ ] Preview in mock Play Store listing (use Google's preview tool)
- [ ] Get feedback from 2-3 people

---

## 7. Tools & Resources

### Design Tools (Free Options)
- **Figma:** https://figma.com
  - Best for UI design and mockups
  - Free tier includes unlimited files
  - Collaboration features
  
- **GIMP:** https://gimp.org
  - Free Photoshop alternative
  - Great for photo editing and overlays
  - Plugin ecosystem
  
- **Inkscape:** https://inkscape.org
  - Vector graphics editor
  - Best for icon design
  - Export to PNG at any resolution

### Screenshot Tools
- **Android Studio Device Manager:** Built-in screenshot tool
- **scrcpy:** https://github.com/Genymobile/scrcpy (screen mirror + capture)
- **ADB:** `adb shell screencap -p /sdcard/screen.png`

### Verification Tools
- **ImageMagick:** Check dimensions and file size
  ```powershell
  magick identify screenshot.png
  ```
  
- **Contrast Checker:** https://webaim.org/resources/contrastchecker/
  - Verify WCAG compliance for text overlays

### Reference Resources
- **Material Design 3:** https://m3.material.io/
- **Play Store Guidelines:** https://support.google.com/googleplay/android-developer/answer/9866151
- **Internet Archive Branding:** https://archive.org/about/
- **Android Asset Studio:** https://romannurik.github.io/AndroidAssetStudio/

---

## 8. Placeholder Asset Status

### ✅ Completed
- [x] Comprehensive specifications document (this file)
- [x] Screenshot plan with 8 detailed screens
- [x] Tablet screenshot plan with 4 screens
- [x] Icon design concepts (3 options)
- [x] Feature graphic layout concept
- [x] Directory structure defined
- [x] Tools and resources listed
- [x] Quick start checklist created

### ⏳ TODO (Need Design Tools)
- [ ] Generate actual 512×512 icon PNG
- [ ] Create 1024×500 feature graphic
- [ ] Capture 8 phone screenshots from running app
- [ ] Capture 4 tablet screenshots
- [ ] Add text overlays to all screenshots
- [ ] Export final assets in correct formats

---

## 9. Hiring a Designer (Alternative)

If you prefer to hire someone:

### Platforms
- **Fiverr:** $50-150 for complete asset package
- **Upwork:** $100-300 for professional designer
- **99designs:** Contest-based, $200-500

### What to Provide Designer
1. This specifications document
2. APK file or screenshots from your device
3. Brand colors and preferences
4. Timeline (typically 2-3 days)

### Deliverables to Request
- App icon source file (PSD/AI/FIG) + PNG export
- Feature graphic source + PNG export
- All 8 phone screenshots with overlays
- All 4 tablet screenshots
- Editable source files for future updates

---

## 10. Next Steps

### Option A: DIY Creation (4-6 hours)
1. Install Figma or GIMP
2. Follow Quick Start Checklist (Section 6)
3. Create icon using one of three concepts
4. Capture screenshots from running app
5. Add text overlays and export

### Option B: Hire Designer (2-3 days, $50-150)
1. Post job on Fiverr/Upwork
2. Provide this document + sample screenshots
3. Review drafts and provide feedback
4. Receive final assets

### Option C: Hybrid (3-4 hours)
1. Capture screenshots yourself (1 hour)
2. Use free icon generator for placeholder (30 min)
3. Hire designer just for icon + feature graphic ($30-50)
4. Add text overlays yourself using templates (1-2 hours)

---

## Summary

This guide provides everything needed to create Play Store visual assets showcasing the NEW navigation system (bottom nav with 5 tabs). All specifications, dimensions, concepts, and tools are documented.

**Recommended Path:** 
1. Capture screenshots showing new navigation (1-2 hours)
2. Use Figma free tier for icon and feature graphic (2-3 hours)
3. Add text overlays in Figma (1 hour)
4. Export and verify all assets (30 min)

**Total Time:** 4-6 hours for complete DIY approach

**Critical Note:** The navigation redesign is now complete, so these screenshots will show the improved UX with bottom navigation instead of the old overcrowded app bar.

---

**Document Status:** Complete ✅  
**Assets Status:** Specifications ready, creation pending  
**Last Updated:** January 15, 2025
