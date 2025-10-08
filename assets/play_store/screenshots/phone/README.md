# Phone Screenshots Placeholder

## Required Specifications

**Count:** 8 images (minimum 2 required, 8 recommended)  
**Dimensions:** Minimum 1080×1920px (9:16 aspect ratio)  
**Format:** PNG or JPEG (PNG preferred for text overlays)  
**File Size:** Under 8MB each  

---

## Screenshot Plan

### 01_home.png ⭐ NEW NAVIGATION
**Purpose:** Show bottom navigation and search

**Capture:**
- Bottom navigation with Home tab active
- Search bar in app bar
- Recent searches or content
- Clean first impression

**Text Overlay:** "Explore 40M+ Items from Internet Archive"

---

### 02_search_results.png
**Purpose:** Demonstrate search functionality

**Capture:**
- Search results (e.g., "Public Domain Books")
- Multiple result cards
- Filter button highlighted
- Bottom navigation visible

**Text Overlay:** "Search & Filter 40M+ Digital Items"

---

### 03_archive_detail.png
**Purpose:** Show metadata and download options

**Capture:**
- Archive detail with metadata
- File list visible
- Download button prominent

**Text Overlay:** "View Detailed Metadata & Files"

---

### 04_transfers.png ⭐ NEW NAVIGATION
**Purpose:** Highlight NEW transfers tab

**Capture:**
- Bottom navigation: Transfers tab active
- Segmented control: Active/Completed/Failed/Queue
- Multiple downloads with progress bars
- Pause/resume controls

**Text Overlay:** "Manage Downloads with Queue & Priority"

---

### 05_library.png ⭐ NEW NAVIGATION
**Purpose:** Show library organization

**Capture:**
- Bottom navigation: Library tab active
- Segmented control: Collections/Downloads/Favorites
- Grid/list of saved items

**Text Overlay:** "Organize Your Library by Collections"

---

### 06_favorites.png ⭐ NEW NAVIGATION
**Purpose:** Show favorites feature

**Capture:**
- Bottom navigation: Favorites tab active
- List of favorited archives
- Heart icons visible

**Text Overlay:** "Save Favorites for Quick Access"

---

### 07_advanced_search.png
**Purpose:** Show advanced filtering

**Capture:**
- Advanced search screen/modal
- Filter options: media type, date, collection, sort
- Material Design 3 chips

**Text Overlay:** "Advanced Filters for Precise Search"

---

### 08_settings_dark.png ⭐ NEW NAVIGATION
**Purpose:** Show customization and dark mode

**Capture:**
- Bottom navigation: Settings tab active
- Dark mode ENABLED
- Settings: downloads, storage, bandwidth
- MD3 switches/sliders

**Text Overlay:** "Customize Downloads & Preferences"

---

## How to Capture

### Step 1: Prepare App
```powershell
# Build release version
flutter build apk --release --flavor production

# Install on device/emulator
flutter install --flavor production
```

### Step 2: Set Up Content
- Search for "Public Domain Books" or "Classical Music"
- Start 2-3 downloads
- Add 5-6 favorites
- Create 1-2 collections

### Step 3: Take Screenshots
- Use Android Studio: View → Running Devices → Screenshot
- Or device: Power + Volume Down
- Save as: `screenshot_01_home.png` through `screenshot_08_settings.png`

### Step 4: Add Text Overlays
Use Figma/GIMP to add:
- Dark overlay bar at top (40% alpha)
- White text (48-64px Roboto Bold)
- Ensure WCAG AA contrast (4.5:1 minimum)

---

## Screenshot Template

```
┌─────────────────────────────────┐
│ ╔═════════════════════════════╗ │ <- Dark overlay (alpha 60%)
│ ║ "Feature Description"       ║ │    White text (48-64px)
│ ╚═════════════════════════════╝ │
│                                 │
│                                 │
│    [ACTUAL APP SCREENSHOT]      │
│                                 │
│                                 │
│    ┌───┬───┬───┬───┬───┐       │ <- Bottom nav visible
│    │ H │ L │ F │ T │ S │       │
│    └───┴───┴───┴───┴───┘       │
└─────────────────────────────────┘
```

---

## Verification

```powershell
# Check dimensions
magick identify *.png

# Should be at least 1080x1920 or larger
```

---

## Files to Create

Place in this directory:
- [ ] `01_home.png` - Home screen with NEW bottom nav
- [ ] `02_search_results.png` - Search results
- [ ] `03_archive_detail.png` - Archive detail page
- [ ] `04_transfers.png` - NEW Transfers tab
- [ ] `05_library.png` - NEW Library tab
- [ ] `06_favorites.png` - NEW Favorites tab
- [ ] `07_advanced_search.png` - Advanced search
- [ ] `08_settings_dark.png` - Settings with dark mode

---

**Status:** ⏳ Placeholder - Need to capture actual screenshots  
**Critical:** Screenshots MUST show NEW bottom navigation (5 tabs)  
**See:** `../../../docs/features/VISUAL_ASSETS_GUIDE.md` for detailed guide
