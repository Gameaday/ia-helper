# Feature Graphic Placeholder

## Required Specifications

**File:** `feature_1024x500.png`

**Dimensions:** 1024 × 500 pixels (exactly)  
**Format:** PNG or JPEG (PNG preferred for text clarity)  
**Aspect Ratio:** 1024:500 (must be exact)  
**File Size:** Under 1MB  
**Purpose:** Hero image displayed at top of Play Store listing

---

## Layout Concept

```
┌──────────────────────────────────────────────────────┐
│  [App Icon]                                          │
│   256×256                                            │
│                                                      │
│  IA Helper                                           │
│  Download from Internet Archive                      │
│                                                      │
│  [Screenshot Preview]  • Fast Downloads              │
│                        • Search & Filter             │
│                        • Library Management          │
└──────────────────────────────────────────────────────┘
```

---

## Content Elements

### Left Side (500×500px)
- App icon at 256×256px
- App name "IA Helper" (64px Roboto Bold)
- Tagline "Download from Internet Archive" (32px Roboto Regular)

### Right Side (524×500px)
- Screenshot preview (blurred/faded, 30% opacity)
- Key feature bullets with icons (24px Roboto Medium)
- Material Design 3 cards/elevation

---

## Color Scheme

**Background Gradient:** `#2C5F9F` → `#1A3A5F` (dark blue)  
**Text:** White (ensure WCAG AA contrast: 4.5:1 minimum)  
**Accents:** Orange `#FF6B35` for highlights  
**Screenshot Overlay:** 30% opacity white  

---

## Alternative Designs

### Design A: App Showcase
Large phone mockup showing app interface with floating UI elements

### Design B: Feature Grid
3×2 grid of feature icons with labels

### Design C: Hero Screenshot
Full-width screenshot with gradient overlay and text

---

## Typography

- **App Name:** 64px, Roboto Bold, White
- **Tagline:** 32px, Roboto Regular, White (90% opacity)
- **Features:** 24px, Roboto Medium, White

---

## How to Create

1. Open Figma/Photoshop/GIMP
2. Create new document: 1024×500px
3. Add dark blue gradient background
4. Place app icon (256×256) on left side
5. Add app name and tagline with proper typography
6. Add screenshot preview on right with overlay
7. Add feature bullets with Material Icons
8. Export as PNG (preferred) or JPEG
9. Save as `feature_1024x500.png` in this directory

---

## Verification

```powershell
# Check dimensions
magick identify feature_1024x500.png

# Should output: feature_1024x500.png PNG 1024x500 ...
```

---

## Contrast Verification

Verify text contrast ratios:
- Use: https://webaim.org/resources/contrastchecker/
- Minimum: 4.5:1 (WCAG AA)
- Target: 7:1 (WCAG AAA)

---

**Status:** ⏳ Placeholder - Need to create actual graphic  
**See:** `../../docs/features/VISUAL_ASSETS_GUIDE.md` for detailed specifications
