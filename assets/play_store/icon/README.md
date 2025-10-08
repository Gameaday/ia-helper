# App Icon Placeholder

## Required Specifications

**File:** `icon_512x512.png`

**Dimensions:** 512 × 512 pixels  
**Format:** 32-bit PNG with alpha channel  
**Color Space:** sRGB  
**File Size:** Under 1MB  
**Safe Area:** Keep important elements within 426×426px center (83%)

---

## Design Concepts

Choose one of three concepts from `../../docs/features/VISUAL_ASSETS_GUIDE.md`:

### Option A: Archive Logo Focus
Internet Archive temple icon with "IA" letters overlaid

### Option B: Download + Archive  
Download arrow combining with archive temple - modern, action-oriented

### Option C: Minimalist
Simple "IA" lettermark with download indicator - clean, modern

---

## Color Palette

**Primary:** `#2C5F9F` (Internet Archive blue)  
**Secondary:** `#5E8CC2` (lighter blue)  
**Accent:** `#FF6B35` (orange for download indicator)  
**Background:** White or transparent  

**Dark Mode Variant:** Consider dark background with light icon

---

## Tools

- **Figma:** https://figma.com (free tier)
- **GIMP:** https://gimp.org (free, open source)
- **Inkscape:** https://inkscape.org (free, vector graphics)
- **Adobe Illustrator:** Professional option

---

## Export Settings

```
Resolution: 512×512px @1x
Format: PNG-24 with alpha
Color space: sRGB
No compression artifacts
```

---

## How to Create

1. Open design tool (Figma/GIMP/Inkscape)
2. Create new document: 512×512px
3. Design icon following Material Design 3 guidelines
4. Keep important elements within 426×426px safe area
5. Export as PNG-24 with alpha channel
6. Save as `icon_512x512.png` in this directory

---

## Verification

```powershell
# Check dimensions
magick identify icon_512x512.png

# Should output: icon_512x512.png PNG 512x512 ...
```

---

**Status:** ⏳ Placeholder - Need to create actual icon  
**See:** `../../docs/features/VISUAL_ASSETS_GUIDE.md` for detailed specifications
