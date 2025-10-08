# Tablet Screenshots Placeholder

## Required Specifications

**Count:** 4 images (minimum 2 required, 4 recommended)  
**Dimensions:** Minimum 1536×2048px (7-inch portrait) or 2048×1536px (landscape)  
**Format:** PNG or JPEG (PNG preferred)  
**File Size:** Under 8MB each  
**Purpose:** Show tablet-optimized layouts and responsive design

---

## Screenshot Plan

### 01_home_landscape.png
**Purpose:** Show adaptive layout for tablets

**Capture:**
- Wider layout with more content visible
- Two-pane layout if applicable (master-detail)
- Bottom navigation adjusted for tablet
- Search bar and results side-by-side

**Text Overlay:** "Optimized for Tablets & Large Screens"

**Dimensions:** 2048×1536px (landscape) or 1536×2048px (portrait)

---

### 02_library_grid.png
**Purpose:** Show grid layout optimization

**Capture:**
- Library screen with 3-4 column grid
- More items visible than phone version
- Proper spacing and padding for larger screens
- Bottom navigation

**Text Overlay:** "Browse Collections in Grid View"

**Dimensions:** 1536×2048px (portrait recommended)

---

### 03_downloads.png
**Purpose:** Show transfers with more detail

**Capture:**
- Transfers screen with expanded information
- Multiple downloads with full metadata visible
- Progress bars, file sizes, timestamps
- Possible two-pane: queue list + detail

**Text Overlay:** "Manage Multiple Downloads Efficiently"

**Dimensions:** 2048×1536px (landscape) or 1536×2048px (portrait)

---

### 04_split_view.png
**Purpose:** Show advanced tablet features

**Capture:**
- Search results on left (40% width)
- Archive detail on right (60% width)
- Demonstrates responsive design
- Professional, desktop-like layout

**Text Overlay:** "Split-Screen Multitasking"

**Dimensions:** 2048×1536px (landscape recommended)

---

## How to Capture

### Step 1: Set Up Tablet Emulator
```powershell
# Use Android Studio emulator
# Recommended devices:
# - Pixel Tablet (2560 x 1600, 276 dpi)
# - Nexus 9 (2048 x 1536, 288 dpi)
# - Galaxy Tab S7 (2560 x 1600, 274 dpi)

flutter run --release --flavor production
```

### Step 2: Prepare Content
Same as phone screenshots:
- Search results populated
- Downloads in progress
- Collections visible
- Favorites added

### Step 3: Capture Screenshots
- Android Studio: View → Running Devices → Screenshot
- Save with descriptive names
- Use both portrait and landscape orientations

### Step 4: Add Text Overlays
- Dark overlay bar (40% alpha)
- White text (64-96px for tablet, larger than phone)
- WCAG AA contrast (4.5:1 minimum)

---

## Layout Differences from Phone

### What to Highlight
- **Grid layouts:** 3-4 columns instead of 1-2
- **Two-pane views:** Master-detail layouts
- **More content:** Take advantage of screen space
- **Landscape mode:** Show how UI adapts
- **Navigation:** Bottom nav adjusts for wider screens

### Don't Just Scale Phone UI
- Show actual tablet-specific features
- Demonstrate responsive design
- Highlight productivity improvements
- Use landscape orientation where beneficial

---

## Screenshot Template (Landscape)

```
┌───────────────────────────────────────────────────┐
│ ╔═════════════════════════════════════════════╗   │
│ ║ "Feature Description for Tablets"           ║   │
│ ╚═════════════════════════════════════════════╝   │
│                                                   │
│  [LEFT PANE]              [RIGHT PANE]            │
│  Search results           Archive detail          │
│  or list view             or expanded info        │
│                                                   │
│  ┌─────┬─────┬─────┬─────┬─────┐                 │
│  │  H  │  L  │  F  │  T  │  S  │ <- Bottom nav   │
│  └─────┴─────┴─────┴─────┴─────┘                 │
└───────────────────────────────────────────────────┘
```

---

## Verification

```powershell
# Check dimensions
magick identify *.png

# Should be at least 1536x2048 (portrait) or 2048x1536 (landscape)
```

---

## Files to Create

Place in this directory:
- [ ] `01_home_landscape.png` - Home/search (2048×1536)
- [ ] `02_library_grid.png` - Library grid view (1536×2048)
- [ ] `03_downloads.png` - Transfers with detail (1536×2048 or 2048×1536)
- [ ] `04_split_view.png` - Split-screen layout (2048×1536)

---

## Recommended Orientations

| Screenshot | Orientation | Reason |
|------------|-------------|--------|
| Home | Landscape | Show two-pane layout |
| Library | Portrait | Show grid with more items |
| Downloads | Either | Based on layout design |
| Split View | Landscape | Emphasize multitasking |

---

**Status:** ⏳ Placeholder - Need to capture actual tablet screenshots  
**Critical:** Must show tablet-optimized layouts, not just scaled phone UI  
**See:** `../../../docs/features/VISUAL_ASSETS_GUIDE.md` for detailed guide
